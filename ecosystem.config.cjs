const projectDir = __dirname;
const sudoUser = process.env.SUDO_USER;
const bunBin = process.env.BUN_BIN || (sudoUser ? `/home/${sudoUser}/.bun/bin/bun` : "bun");

module.exports = {
  apps: [
    {
      name: "go-domain",
      script: bunBin,
      args: "run server.ts",
      interpreter: "none",
      cwd: projectDir,
      env: {
        GO_DOMAIN_HOME: "/var/lib/go-domain"
      },
      out_file: "/var/lib/go-domain/logs/go-domain.out.log",
      error_file: "/var/lib/go-domain/logs/go-domain.err.log"
    },
    {
      name: "caddy",
      script: "/usr/bin/caddy",
      interpreter: "none",
      args: "run --config /var/lib/go-domain/Caddyfile",
      out_file: "/var/lib/go-domain/logs/caddy.out.log",
      error_file: "/var/lib/go-domain/logs/caddy.err.log"
    }
  ]
};
