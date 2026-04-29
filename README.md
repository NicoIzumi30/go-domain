# Go Domain

A lightweight, web-based local domain manager running as a background service. It provides a Vercel-inspired dashboard to easily manage local domains (e.g., `.test` or `.local`) and proxy them to your local development ports with automatic self-signed HTTPS.

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

1. **Windows 10/11**: The application must be run as an **Administrator** to allow modifications to the system's `hosts` file.
2. **Node.js & npm**: Required to install PM2 and Bun globally.
3. **Bun Runtime:** Install globally via npm:
   ```bash
   npm install -g bun
   ```
4. **Caddy Server:** Included within the project directory (`caddy.exe`).

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

### 2. System Configuration (`C:\ProgramData\GoDomain`)
The application persists data and generated configurations in the Windows `ProgramData` directory:
```text
C:\ProgramData\GoDomain\
├── config.json             # JSON database storing domain aliases
├── Caddyfile               # Auto-generated configuration for the Caddy reverse proxy
└── backups\                # Automated backups of the system `hosts` and `Caddyfile`
```

---

## Installation & Setup

Follow these steps to install and run **Go Domain** on your machine:

### Step 1: Project Setup
1. Open PowerShell or Command Prompt **AS ADMINISTRATOR**. This is mandatory for modifying the `C:\Windows\System32\drivers\etc\hosts` file.
2. Clone this repository or navigate to the project directory:
   ```bash
   cd path/to/go-domain
   ```
3. Install dependencies using Bun:
   ```bash
   bun install
   ```

### Step 2: Starting the Background Service
1. Start the web dashboard and Caddy server as background processes using PM2:
   ```bash
   bunx pm2 start ecosystem.config.cjs
   ```
2. Verify that both services are online:
   ```bash
   bunx pm2 status
   ```

### Step 3: Accessing the Dashboard
1. Open your browser and navigate to:
   **http://localhost:3333**
2. Add a new domain alias (e.g., Domain: `myapp`, TLD: `.test`, Target: `localhost:8000`).
3. Click "Add Alias".
4. Navigate to `https://myapp.test` in your browser. The reverse proxy and HTTPS will be handled automatically.

---

## Auto HTTPS & Supported TLDs

Go Domain automatically configures Caddy to issue **Local TLS (Self-Signed HTTPS)** certificates for domains using the following Top-Level Domains (TLDs):

`.test`, `.local`, `.localhost`, `.internal`, `.example`, `.invalid`, `.lan`, `.dev.local`, `.app.local`, `.site.local`, `.project.local`

---

## Maintenance Commands

Since the application runs as a background daemon via PM2, use the following commands for maintenance (must be executed as Administrator):

- **Check service status:** `bunx pm2 status`
- **View activity/error logs:** `bunx pm2 logs`
- **Restart services:** `bunx pm2 restart ecosystem.config.cjs`
- **Stop all services:** `bunx pm2 stop all`
