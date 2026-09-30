#!/usr/bin/env bash
# =============================================================================
# SEO Office — full toolkit setup
# =============================================================================
# Installs SEO Office first, then the companion tools:
#   - Claude Code plugins: claude-seo, claude-obsidian, claude-ads,
#     claude-blog, banana-claude
#   - YouTube Pro (a separate local web app)
#   - An Obsidian vault for claude-obsidian (copied from obsidian-vault-template/)
#
# Usage (from your SEO Office folder):
#   bash scripts/setup-toolkit.sh
#
# Optional environment variables:
#   YOUTUBEPRO_DIR=...   where to put YouTube Pro (default: ~/youtubepro)
#   SKIP_SEO_OFFICE=1    skip step 1 (SEO Office already installed)
#   SKIP_PLUGINS=1       skip step 2 (Claude Code plugins)
#   SKIP_YOUTUBEPRO=1    skip step 3 (YouTube Pro)
#   VAULT_DIR=...        where to create the Obsidian vault
#                        (default: ~/Documents/SEO-Office-Vault)
#   SKIP_VAULT=1         skip step 4 (Obsidian vault)
#
# Safe to re-run: each step skips what is already installed. It never
# overwrites .env or .env.local files and never prints API keys.
#
# Step-by-step guide: docs/SETUP-GUIDE.md
# =============================================================================

# No `set -e`: one failed plugin should not stop the others. Failures are
# collected and reported at the end.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
YOUTUBEPRO_DIR="${YOUTUBEPRO_DIR:-$HOME/youtubepro}"
YOUTUBEPRO_REPO="https://github.com/AgriciDaniel/youtubepro.git"

# Native Windows shells (Git Bash, MSYS, Cygwin) cannot run SEO Office.
# Stop early with the fix instead of failing halfway through.
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    cat >&2 <<'EOF'

  This is Windows, not Linux. SEO Office runs on Windows through WSL
  (a free Linux layer built into Windows).

  1. Open PowerShell as Administrator and run:   wsl --install
  2. Restart the PC. Ubuntu opens and asks you to pick a username/password.
  3. In the Ubuntu window, run the commands in docs/SETUP-GUIDE.md
     under "Windows: run everything inside Ubuntu".

EOF
    exit 1
    ;;
esac

# Inside WSL, put the vault in the Windows Documents folder so the Windows
# Obsidian app can open it directly.
is_wsl() { grep -qi microsoft /proc/version 2>/dev/null; }
default_vault_dir() {
  if is_wsl && command -v wslpath >/dev/null 2>&1 && command -v cmd.exe >/dev/null 2>&1; then
    local win_home
    win_home=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')
    if [[ -n "$win_home" && "$win_home" != *%* ]]; then
      local unix_home
      unix_home=$(wslpath -u "$win_home" 2>/dev/null)
      if [[ -n "$unix_home" && -d "$unix_home" ]]; then
        printf '%s/Documents/SEO-Office-Vault' "$unix_home"
        return
      fi
    fi
  fi
  printf '%s/Documents/SEO-Office-Vault' "$HOME"
}
VAULT_DIR="${VAULT_DIR:-$(default_vault_dir)}"
VAULT_TEMPLATE="$REPO_ROOT/obsidian-vault-template"

# "<marketplace GitHub repo>|<plugin>@<marketplace name>"
# Marketplace names come from each repo's .claude-plugin/marketplace.json.
PLUGINS=(
  "AgriciDaniel/claude-seo|claude-seo@agricidaniel-claude-seo"
  "AgriciDaniel/claude-obsidian|claude-obsidian@agricidaniel-claude-obsidian"
  "AgriciDaniel/claude-ads|claude-ads@ai-marketing-hub-claude-ads"
  "AgriciDaniel/claude-blog|claude-blog@agricidaniel-blog"
  "AgriciDaniel/banana-claude|banana-claude@banana-claude-marketplace"
)

# -------- pretty printing ------------------------------------------------------
c_reset=$'\033[0m'; c_bold=$'\033[1m'; c_dim=$'\033[2m'
c_blue=$'\033[34m'; c_green=$'\033[32m'; c_yellow=$'\033[33m'; c_red=$'\033[31m'

step()  { printf "\n%s==> %s%s\n" "$c_blue$c_bold" "$1" "$c_reset"; }
info()  { printf "    %s%s%s\n" "$c_dim" "$1" "$c_reset"; }
ok()    { printf "    %s✓ %s%s\n" "$c_green" "$1" "$c_reset"; }
warn()  { printf "    %s! %s%s\n" "$c_yellow" "$1" "$c_reset"; }
fail()  { printf "    %s✗ %s%s\n" "$c_red" "$1" "$c_reset" >&2; exit 1; }
indent() { sed 's/^/      /'; }

load_nvm() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  # shellcheck disable=SC1091
  [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
  return 0
}

FAILED=()
note_failure() { FAILED+=("$1"); }

# -------- 1. SEO Office -------------------------------------------------------
if [[ "${SKIP_SEO_OFFICE:-0}" == "1" ]]; then
  step "1/4  SEO Office (skipped)"
else
  step "1/4  SEO Office"
  info "Running the SEO Office installer in $REPO_ROOT"
  # INSTALL_DIR points at this checkout, so the installer skips its own clone.
  if ! INSTALL_DIR="$REPO_ROOT" bash "$REPO_ROOT/scripts/install.sh"; then
    fail "SEO Office did not install. Fix the error above, then re-run this script."
  fi
  ok "SEO Office installed"
fi

# The installer may have installed Node through nvm in its own shell.
load_nvm

# -------- 2. Claude Code plugins ---------------------------------------------
if [[ "${SKIP_PLUGINS:-0}" == "1" ]]; then
  step "2/4  Claude Code plugins (skipped)"
elif ! command -v claude >/dev/null 2>&1; then
  step "2/4  Claude Code plugins"
  warn "Claude Code (the 'claude' command) is not installed or not on your PATH."
  info "Install it from https://code.claude.com/docs, sign in, then re-run:"
  info "  SKIP_SEO_OFFICE=1 bash scripts/setup-toolkit.sh"
  note_failure "Claude Code plugins (Claude Code not installed)"
else
  step "2/4  Claude Code plugins"
  for entry in "${PLUGINS[@]}"; do
    repo="${entry%%|*}"
    plugin="${entry##*|}"

    if out=$(claude plugin marketplace add "$repo" 2>&1); then
      ok "marketplace ready: $repo"
    else
      warn "could not add marketplace $repo"
      printf '%s\n' "$out" | indent
      note_failure "$plugin (marketplace add failed)"
      continue
    fi

    if out=$(claude plugin install "$plugin" 2>&1); then
      ok "plugin ready: $plugin"
    else
      warn "could not install $plugin"
      printf '%s\n' "$out" | indent
      note_failure "$plugin (install failed)"
    fi
  done
fi

# -------- 3. YouTube Pro -----------------------------------------------------
if [[ "${SKIP_YOUTUBEPRO:-0}" == "1" ]]; then
  step "3/4  YouTube Pro (skipped)"
else
  step "3/4  YouTube Pro"
  node_ok=0
  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    nodever=$(node --version | sed 's/^v//')
    major=${nodever%%.*}
    rest=${nodever#*.}
    minor=${rest%%.*}
    # YouTube Pro needs Node 22.12 or newer.
    if (( major > 22 || (major == 22 && minor >= 12) )); then
      node_ok=1
    else
      warn "Node $nodever is too old for YouTube Pro (needs 22.12+)."
    fi
  else
    warn "Node.js / npm not found."
  fi

  if [[ "$node_ok" != "1" ]]; then
    note_failure "YouTube Pro (Node 22.12+ required)"
  else
    yt_ready=1
    if [[ -d "$YOUTUBEPRO_DIR/.git" ]]; then
      info "$YOUTUBEPRO_DIR already exists — using it"
    elif [[ -e "$YOUTUBEPRO_DIR" ]]; then
      warn "$YOUTUBEPRO_DIR exists but is not a git checkout. Move it or set YOUTUBEPRO_DIR."
      note_failure "YouTube Pro (folder conflict)"
      yt_ready=0
    elif git clone "$YOUTUBEPRO_REPO" "$YOUTUBEPRO_DIR"; then
      ok "cloned to $YOUTUBEPRO_DIR"
    else
      note_failure "YouTube Pro (clone failed)"
      yt_ready=0
    fi

    if [[ "$yt_ready" == "1" ]]; then
      if (cd "$YOUTUBEPRO_DIR" && npm install); then
        ok "npm install complete"
      else
        note_failure "YouTube Pro (npm install failed)"
      fi

      if [[ -f "$YOUTUBEPRO_DIR/.env" ]]; then
        warn ".env already exists — not overwriting"
      elif [[ -f "$YOUTUBEPRO_DIR/.env.example" ]]; then
        cp "$YOUTUBEPRO_DIR/.env.example" "$YOUTUBEPRO_DIR/.env"
        chmod 600 "$YOUTUBEPRO_DIR/.env"
        ok "created .env from template (add keys later in its Settings page)"
      fi

      if [[ "$(uname -s)" == Darwin* ]]; then
        info "macOS tip: if port 5000 is busy (AirPlay Receiver often uses it),"
        info "set PORT=5050 in $YOUTUBEPRO_DIR/.env"
      fi
    fi
  fi
fi

# -------- 4. Obsidian vault --------------------------------------------------
# The template was generated by claude-obsidian's own `init` and passes its
# lint. It lives outside this repo once copied, so client notes never end up
# in git.
if [[ "${SKIP_VAULT:-0}" == "1" ]]; then
  step "4/4  Obsidian vault (skipped)"
else
  step "4/4  Obsidian vault"
  if [[ -e "$VAULT_DIR" ]]; then
    info "$VAULT_DIR already exists — leaving it untouched"
  elif [[ ! -d "$VAULT_TEMPLATE" ]]; then
    warn "vault template not found at $VAULT_TEMPLATE"
    note_failure "Obsidian vault (template missing)"
  elif mkdir -p "$(dirname "$VAULT_DIR")" && cp -R "$VAULT_TEMPLATE" "$VAULT_DIR"; then
    ok "created vault at $VAULT_DIR"
  else
    note_failure "Obsidian vault (copy failed)"
  fi
fi

# -------- summary ------------------------------------------------------------
step "Summary"
if [[ ${#FAILED[@]} -eq 0 ]]; then
  ok "Everything installed."
else
  warn "Some parts need attention:"
  for f in ${FAILED[@]+"${FAILED[@]}"}; do
    info "  - $f"
  done
  info "Fix those, then re-run this script. Finished parts are skipped."
fi

cat <<EOF

${c_bold}Next: finish setup (one-time, about 20 minutes)${c_reset}

  A. Start SEO Office and run its setup wizard
       ${c_bold}cd "$REPO_ROOT" && pnpm dev${c_reset}
       open http://localhost:3000/setup

  B. In a new terminal, open Claude Code and run these one at a time
       ${c_bold}cd "$REPO_ROOT" && claude${c_reset}
       /reload-plugins
       /seo setup        then  /seo doctor
       /ads setup

  C. Start YouTube Pro when you need it
       ${c_bold}cd "$YOUTUBEPRO_DIR" && npm run dev${c_reset}
       open http://127.0.0.1:5000  (or the PORT you set)

  D. Open the vault in Obsidian (free: https://obsidian.md)
       Open folder as vault → $VAULT_DIR
     To build it with Claude:
       ${c_bold}cd "$VAULT_DIR" && claude${c_reset}   then  /claude-obsidian:wiki

Full walkthrough and API key checklist: ${c_dim}docs/SETUP-GUIDE.md${c_reset}
EOF

[[ ${#FAILED[@]} -eq 0 ]]
