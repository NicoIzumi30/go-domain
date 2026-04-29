module.exports = {
  apps: [
    {
      name: "go-domain",
      script: "server.ts",
      interpreter: "bun"
    },
    {
      name: "caddy",
      script: "caddy.exe",
      args: "run --config C:\\ProgramData\\GoDomain\\Caddyfile"
    }
  ]
};
