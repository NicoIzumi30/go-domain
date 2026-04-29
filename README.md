# Go Domain

A lightweight, web-based local domain manager for Ubuntu/Linux. It runs as a background service, provides a Vercel-inspired dashboard to manage local domains (e.g., `.test` or `.local`), and proxies them to local development ports with automatic self-signed HTTPS.

---

## Tech Stack

- **Runtime:** [Bun](https://bun.sh/) - High-performance JavaScript runtime
- **Web Framework:** [Hono](https://hono.dev/) - Ultrafast, lightweight web framework
- **Template Engine:** [Edge.js](https://edgejs.dev/) - Server-side HTML rendering
- **Process Manager:** [PM2](https://pm2.keymetrics.io/) - Daemon process manager for background execution
- **Reverse Proxy:** [Caddy](https://caddyserver.com/) - Enterprise-ready web server with automatic HTTPS

---

## Requirements

Go Domain is intended for Ubuntu Linux. The setup script checks and installs the required tools when they are missing:

- `curl`
- Bun
- PM2, through `bunx pm2`
- Caddy

By default, Go Domain runs Caddy on `80` and `443` so local domains open without a port suffix, for example `https://myapp.test`.

---

## Project Structure

The project architecture is divided into the source code and the system configuration directory.

### 1. Source Code (Go Domain App)
```text
go-domain/
├── server.ts               # Hono web server entry point (Port 3333)
├── manager.ts              # Core logic for hosts editing, Caddyfile generation, and DNS flushing
├── ecosystem.config.cjs    # PM2 configuration to run the Web UI and Caddy in the background
├── setup.sh                # One-time installer and shell shortcut setup
├── package.json            # Project dependencies and scripts
├── scripts/
│   └── go-domain           # Runtime helper for start/status/restart/log commands
├── public/
│   └── styles.css          # Dark Mode UI design system
└── views/
    └── app.edge            # Edge.js HTML templates for the dashboard
```

### 2. System Configuration (`/var/lib/go-domain`)
The application persists data and generated configurations in `/var/lib/go-domain`:
```text
/var/lib/go-domain/
├── config.json             # JSON database storing domain aliases
├── Caddyfile               # Auto-generated configuration for the Caddy reverse proxy
├── backups/                # Automated backups of the system `hosts` and `Caddyfile`
└── logs/                   # PM2 stdout/stderr logs
```

Default runtime ports:

- Dashboard: `http://localhost:3333`
- Caddy HTTP redirect: `http://domain.test`
- Caddy HTTPS proxy: `https://domain.test`
- Go Domain aliases resolve to `127.0.0.2`, so Caddy can use a dedicated loopback address instead of `127.0.0.1`.
- Go Domain Caddy uses admin endpoint `127.0.0.2:2020` so config reloads do not conflict with the default Caddy admin port `127.0.0.1:2019`.

---

## Installation & Setup

Run the setup script from the project directory:

```bash
chmod +x setup.sh
./setup.sh
```

The setup checks for required tools, installs anything missing, prepares `/var/lib/go-domain`, installs project dependencies, disables the default system Caddy service, and adds shell shortcuts to your active shell rc file (`~/.bashrc` or `~/.zshrc`).

There are two scripts by design:

- `setup.sh` is for one-time machine setup.
- `scripts/go-domain` is the runtime helper used by the `gd` shortcut.

After setup, open a new terminal or reload your shell:

```bash
source ~/.bashrc
```

If you use Zsh:

```bash
source ~/.zshrc
```

### Starting the Background Service
1. Start the web dashboard and Caddy server as background processes using PM2:
   ```bash
   gd start
   ```
2. Verify that both services are online:
   ```bash
   gd status
   ```

If the shortcut is not active yet, use the helper directly:

```bash
sudo ./scripts/go-domain start
sudo ./scripts/go-domain status
```

### Accessing the Dashboard
1. Open your browser and navigate to:
   **http://localhost:3333**
2. Add a new domain alias (e.g., Domain: `myapp`, TLD: `.test`, Target: `localhost:8000`).
3. Click "Add Alias".
4. Navigate to `https://myapp.test` in your browser. The reverse proxy and HTTPS will be handled automatically.

---

## Apache Port Conflicts

Only one process can listen on the same IP and port. Go Domain avoids interfering with Apache on `127.0.0.1` by mapping managed domains to `127.0.0.2` and making Caddy bind to `127.0.0.2:80` and `127.0.0.2:443`.

This lets clean URLs work:

```text
https://myapp.test
```

without moving Go Domain to `:8443`.

Important: this works when Apache is not listening on every address. If Apache uses wildcard listeners such as `Listen 80`, `Listen 443`, `*:80`, or `*:443`, it may still occupy `127.0.0.2`. In that case, narrow Apache to the IP it should serve, while leaving Go Domain on `127.0.0.2`.

Use one of these approaches:

- **Recommended for local Ubuntu:** Keep Apache on `127.0.0.1` or the server's real LAN/public IP, and let Go Domain use `127.0.0.2`.
- **If Apache is not needed:** Stop/disable Apache.
- **If Apache must serve public sites:** Bind Apache to the public IP explicitly, then keep Go Domain on `127.0.0.2`.

To keep Apache on localhost while freeing `127.0.0.2`, edit Apache ports and virtual hosts:

```bash
sudo sed -i 's/^Listen 80$/Listen 127.0.0.1:80/' /etc/apache2/ports.conf
sudo sed -i 's/^Listen 443$/Listen 127.0.0.1:443/' /etc/apache2/ports.conf
sudo grep -R "<VirtualHost \\*:80>" -n /etc/apache2/sites-available
```

Then change matching Apache virtual hosts from:

```apache
<VirtualHost *:80>
```

to:

```apache
<VirtualHost 127.0.0.1:80>
```

Restart Apache and Go Domain:

```bash
sudo systemctl restart apache2
gd restart
```

If you also have HTTPS virtual hosts, change `*:443` to `127.0.0.1:443`.

After that, Apache continues to work on `127.0.0.1`, while Go Domain owns `127.0.0.2` for managed local domains.

Go Domain standard port config:

```json
{
  "caddyPath": "caddy",
  "caddyHttpPort": 80,
  "caddyHttpsPort": 443,
  "aliases": []
}
```

---

## Auto HTTPS & Supported TLDs

Go Domain automatically configures Caddy to issue **Local TLS (Self-Signed HTTPS)** certificates for domains using the following Top-Level Domains (TLDs):

`.test`, `.local`, `.localhost`, `.internal`, `.example`, `.invalid`, `.lan`, `.dev.local`, `.app.local`, `.site.local`, `.project.local`

---

## Maintenance Commands

Since the application runs as a background daemon via PM2, use the following commands for maintenance:

- **Check service status:** `gd status`
- **View activity/error logs:** `gd logs`
- **Restart app only:** `gd restart-app`
- **Restart Caddy only:** `gd restart-caddy`
- **Diagnose a domain:** `gd doctor myapp.test`
- **Restart services:** `gd restart`
- **Stop services:** `gd stop`

Direct helper commands are also available:

- **Check service status:** `sudo ./scripts/go-domain status`
- **View activity/error logs:** `sudo ./scripts/go-domain logs`
- **Restart app only:** `sudo ./scripts/go-domain restart-app`
- **Restart Caddy only:** `sudo ./scripts/go-domain restart-caddy`
- **Diagnose a domain:** `sudo ./scripts/go-domain doctor myapp.test`
- **Restart services:** `sudo ./scripts/go-domain restart`
- **Stop services:** `sudo ./scripts/go-domain stop`
