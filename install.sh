#!/usr/bin/env bash
# Installs LiteLLM + clauden. Run from the folder containing clauden and config.yaml.
set -euo pipefail
cd "$(dirname "$0")"
CLAUDEN_HOME="$HOME/.clauden"; BIN="$HOME/.local/bin"
mkdir -p "$CLAUDEN_HOME" "$BIN"

if ! command -v litellm >/dev/null; then
  echo "Installing LiteLLM proxy..."
  if command -v uv >/dev/null;     then uv tool install 'litellm[proxy]'
  elif command -v pipx >/dev/null; then pipx install 'litellm[proxy]'
  else python3 -m pip install --user 'litellm[proxy]'; fi
fi

command -v claude >/dev/null || echo "WARNING: 'claude' not found — install Claude Code: npm i -g @anthropic-ai/claude-code"

cp config.yaml "$CLAUDEN_HOME/config.yaml"
install -m 755 clauden "$BIN/clauden"

if [[ ! -f "$CLAUDEN_HOME/env" ]]; then
  read -rsp "NVIDIA API key (nvapi-..., from build.nvidia.com): " KEY; echo
  printf 'export NVIDIA_NIM_API_KEY=%q\n# export CLAUDEN_FAST_MODEL=deepseek-v4.1-flash\n' "$KEY" > "$CLAUDEN_HOME/env"
  chmod 600 "$CLAUDEN_HOME/env"
fi

case ":$PATH:" in *":$BIN:"*) ;; *) echo "Add to your shell rc:  export PATH=\"$BIN:\$PATH\"";; esac
echo "Done. Try:  clauden --list kimi   then   clauden kimi-k3"
