#!/usr/bin/env sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
APP_DIR=${GO_DOMAIN_HOME:-/var/lib/go-domain}
SHORTCUT_NAME=${GO_DOMAIN_SHORTCUT:-gd}

log() {
  printf '%s\n' "==> $*"
}

warn() {
  printf '%s\n' "WARN: $*" >&2
}

need_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    printf '%s\n' "sudo is required to run setup." >&2
    exit 1
  fi
}

run_sudo() {
  sudo "$@"
}

detect_shell_rc() {
  shell_name=$(basename "${SHELL:-}")
  case "$shell_name" in
    zsh)
      printf '%s\n' "$HOME/.zshrc"
      ;;
    bash)
      printf '%s\n' "$HOME/.bashrc"
      ;;
    *)
      if [ -f "$HOME/.zshrc" ]; then
        printf '%s\n' "$HOME/.zshrc"
      else
        printf '%s\n' "$HOME/.bashrc"
      fi
      ;;
  esac
}

ensure_ubuntu() {
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [ "${ID:-}" != "ubuntu" ] && [ "${ID_LIKE:-}" != "ubuntu" ]; then
      warn "This setup is intended for Ubuntu. Continuing anyway."
    fi
  fi
}

ensure_apt_package() {
  package_name=$1
  command_name=${2:-$1}

  if command -v "$command_name" >/dev/null 2>&1; then
    log "$command_name already installed, skipping."
    return
  fi

  log "Installing $package_name..."
  run_sudo apt-get update
  run_sudo apt-get install -y "$package_name"
}

ensure_bun() {
  if command -v bun >/dev/null 2>&1; then
    log "bun already installed, skipping."
    return
  fi

  log "Installing bun for $USER..."
  curl -fsSL https://bun.sh/install | bash
  export PATH="$HOME/.bun/bin:$PATH"

  if ! command -v bun >/dev/null 2>&1; then
    printf '%s\n' "bun installation finished but bun is not on PATH. Open a new terminal and rerun ./setup.sh." >&2
    exit 1
  fi
}

ensure_caddy() {
  if command -v caddy >/dev/null 2>&1; then
    log "caddy already installed, skipping."
  else
    ensure_apt_package caddy caddy
  fi

  if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files caddy.service >/dev/null 2>&1; then
    log "Disabling system caddy service so PM2 can run Go Domain's Caddy instance."
    run_sudo systemctl stop caddy >/dev/null 2>&1 || true
    run_sudo systemctl disable caddy >/dev/null 2>&1 || true
  fi
}

ensure_project_deps() {
  log "Installing project dependencies..."
  (cd "$PROJECT_DIR" && bun install)
}

ensure_app_dir() {
  log "Preparing $APP_DIR..."
  run_sudo mkdir -p "$APP_DIR/logs" "$APP_DIR/backups"
  if [ ! -f "$APP_DIR/Caddyfile" ]; then
    printf '{\n    admin off\n}\n' | run_sudo tee "$APP_DIR/Caddyfile" >/dev/null
  fi
}

install_shortcut() {
  rc_file=$(detect_shell_rc)
  bun_bin=$(command -v bun)
  mkdir -p "$(dirname "$rc_file")"
  touch "$rc_file"

  tmp_file=$(mktemp)
  awk '
    /# >>> go-domain >>>/ { skip = 1; next }
    /# <<< go-domain <<</ { skip = 0; next }
    skip != 1 { print }
  ' "$rc_file" > "$tmp_file"

  cat >> "$tmp_file" <<EOF

# >>> go-domain >>>
export GO_DOMAIN_DIR="$PROJECT_DIR"
godomain() {
  sudo env BUN_BIN="$bun_bin" "\$GO_DOMAIN_DIR/scripts/go-domain" "\$@"
}
alias $SHORTCUT_NAME='godomain'
# <<< go-domain <<<
EOF

  mv "$tmp_file" "$rc_file"
  log "Added shell shortcut to $rc_file."
}

main() {
  if [ "$(id -u)" -eq 0 ]; then
    printf '%s\n' "Run setup as your normal user, not with sudo: ./setup.sh" >&2
    exit 1
  fi

  need_sudo
  ensure_ubuntu
  ensure_apt_package curl curl
  ensure_bun
  ensure_caddy
  ensure_project_deps
  ensure_app_dir
  chmod +x "$PROJECT_DIR/scripts/go-domain"
  install_shortcut

  log "Setup complete."
  printf '\n%s\n' "Open a new terminal or run:"
  printf '%s\n' ". $(detect_shell_rc)"
  printf '\n%s\n' "Then start Go Domain with:"
  printf '%s\n' "$SHORTCUT_NAME start"
  printf '%s\n' "$SHORTCUT_NAME status"
}

main "$@"
