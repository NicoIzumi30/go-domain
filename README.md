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

Before proceeding with the installation, ensure your system meets the following requirements:

1. **Ubuntu Linux**: Run the background service with `sudo` because the app modifies `/etc/hosts`.
2. **Node.js & npm**: Required to install PM2 and Bun globally.
3. **Bun Runtime:** Install globally via npm:
   ```bash
   sudo npm install -g bun
   ```
4. **PM2:** Install globally:
   ```bash
   sudo npm install -g pm2
   ```
5. **Caddy Server:** Install from Ubuntu packages or the official Caddy apt repository so the `caddy` command is available in `PATH`.

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
├── package.json            # Project dependencies and scripts
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

---

## Installation & Setup

Follow these steps to install and run **Go Domain** on your machine:

### Step 1: Project Setup
1. Clone this repository or navigate to the project directory:
   ```bash
   cd path/to/go-domain
   ```
2. Install dependencies using Bun:
   ```bash
   bun install
   ```
3. Create the application data directory:
   ```bash
   sudo mkdir -p /var/lib/go-domain/logs
   printf '{\n    admin off\n}\n' | sudo tee /var/lib/go-domain/Caddyfile
   ```

### Step 2: Starting the Background Service
1. Start the web dashboard and Caddy server as background processes using PM2:
   ```bash
   sudo bunx pm2 start ecosystem.config.cjs
   ```
2. Verify that both services are online:
   ```bash
   sudo bunx pm2 status
   ```

### Step 3: Accessing the Dashboard
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
sudo bunx pm2 restart ecosystem.config.cjs
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

- **Check service status:** `sudo bunx pm2 status`
- **View activity/error logs:** `sudo bunx pm2 logs`
- **Restart services:** `sudo bunx pm2 restart ecosystem.config.cjs`
- **Stop all services:** `sudo bunx pm2 stop all`
