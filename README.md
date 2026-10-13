# clauden

**Run [Claude Code](https://claude.com/claude-code) against [NVIDIA NIM](https://build.nvidia.com) models through a local [LiteLLM](https://github.com/BerriAI/litellm) proxy.**

`clauden` points Claude Code at any model hosted on NVIDIA's inference API — Kimi, DeepSeek, Llama, Qwen, and more — instead of Anthropic's. It starts a small LiteLLM proxy on localhost, maps every Claude model tier to the NVIDIA model you choose, and launches Claude Code against it.

```
Claude Code  ──▶  LiteLLM proxy (127.0.0.1:4000)  ──▶  NVIDIA NIM API
```

---

## Why

Claude Code speaks the Anthropic API. NVIDIA NIM speaks the OpenAI API. LiteLLM translates between the two, so you can drive the Claude Code agent with any NVIDIA-hosted model while keeping the editor, tools, and workflow you already use.

- **One command** to pick a model and start a session: `clauden kimi-k3`
- **Any NVIDIA model** — a wildcard route means you never edit config to try a new one
- **Short names** — `kimi-k3` resolves to `moonshotai/kimi-k3` automatically
- **Separate fast model** — route Claude Code's background calls to a cheaper/faster model
- **Local only** — the proxy binds to `127.0.0.1`; your key stays on your machine

---

## Requirements

- **[Claude Code](https://claude.com/claude-code)** — `npm i -g @anthropic-ai/claude-code`
- **Python 3.9+** and one of [`uv`](https://docs.astral.sh/uv/) (recommended), [`pipx`](https://pipx.pypa.io/), or `pip`
- An **NVIDIA API key** (`nvapi-...`) from [build.nvidia.com](https://build.nvidia.com)
- `bash`, `curl`, `python3`

---

## Install

```bash
git clone https://github.com/<your-username>/clauden.git
cd clauden
./install.sh
```

The installer will:

1. Install the LiteLLM proxy (via `uv`, `pipx`, or `pip` — whichever is available)
2. Copy `config.yaml` to `~/.clauden/config.yaml`
3. Install the `clauden` command to `~/.local/bin`
4. Prompt once for your NVIDIA API key and save it to `~/.clauden/env` (mode `600`)

If `~/.local/bin` isn't on your `PATH`, the installer tells you the line to add to your shell rc:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## Usage

```bash
clauden <model> [claude args...]     # start a Claude Code session on an NVIDIA model
clauden --list [filter]              # list model ids available on your key
clauden --stop                       # stop the background proxy
clauden --logs                       # tail the proxy log
clauden --help                       # show usage
```

### Examples

```bash
clauden --list kimi                  # see which Kimi models you can use
clauden kimi-k3                      # start a session (short name is resolved)
clauden moonshotai/kimi-k3           # or use the full id
clauden kimi-k3 -p "explain this repo"   # pass any Claude Code flags through
```

The first run on a given model starts the proxy (a few seconds); later runs reuse it.

---

## Configuration

Settings live in `~/.clauden/env` and can be exported in your shell. Only the API key is required.

| Variable | Default | Purpose |
| --- | --- | --- |
| `NVIDIA_NIM_API_KEY` | — (required) | Your `nvapi-...` key from build.nvidia.com |
| `CLAUDEN_FAST_MODEL` | same as main model | Model for Claude Code's background/haiku-tier calls |
| `CLAUDEN_PORT` | `4000` | Local proxy port |
| `CLAUDEN_HOME` | `~/.clauden` | Config / log / cache directory |
| `LITELLM_MASTER_KEY` | `sk-clauden-local` | Local-only token between Claude Code and the proxy (not a secret) |

### Changing your API key

Edit the key in `~/.clauden/env`, then restart the proxy so it picks up the change:

```bash
clauden --stop
```

The proxy reads the key once at startup, so a running proxy keeps the old key until restarted.

---

## How it works

- **`config.yaml`** defines a single wildcard route, `nvidia_nim/*`, pointed at `https://integrate.api.nvidia.com/v1`. Any model id passes straight through, so you never edit this file to try a new model. `drop_params` strips Anthropic-only parameters the model doesn't accept, and requests retry on the free tier's rate limits.
- **`clauden`** resolves your short model name against the `/models` list (cached 24h), starts the proxy if it isn't already running, then exports the `ANTHROPIC_*` environment variables that redirect Claude Code to the proxy and launches `claude`.

Because `clauden` sets `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN`, those env vars apply only to the session it launches — running plain `claude` elsewhere still uses your normal Anthropic/claude.ai login.

---

## Troubleshooting

**`claude.ai connectors are disabled because ... another auth source is set`**
Expected. `clauden` deliberately points Claude Code at the local proxy, which disables claude.ai connectors for that session only. Run plain `claude` for your normal login.

**`There's an issue with the selected model ... It may not exist or you may not have access`**
The model id isn't served to your key, or your key is invalid for inference. Confirm with `clauden --list <name>`, and test your key directly:

```bash
source ~/.clauden/env
curl -s -o /dev/null -w "%{http_code}\n" \
  -H "Authorization: Bearer $NVIDIA_NIM_API_KEY" \
  -H "Content-Type: application/json" \
  https://integrate.api.nvidia.com/v1/chat/completions \
  -d '{"model":"moonshotai/kimi-k3","max_tokens":5,"messages":[{"role":"user","content":"hi"}]}'
```

`200` means the key and model are good; `403` means auth, `404` means the model id is wrong. Check `clauden --logs` for the proxy's view.

**Proxy won't start**
Make sure `litellm` is installed (`uv tool install 'litellm[proxy]'`) and `~/.clauden/config.yaml` exists (re-run `./install.sh`). Inspect `clauden --logs`.

---

## Files

| File | Role |
| --- | --- |
| `clauden` | The CLI: resolves the model, manages the proxy, launches Claude Code |
| `config.yaml` | LiteLLM proxy configuration (wildcard NVIDIA route) |
| `install.sh` | Installs LiteLLM, the `clauden` command, and the config |

Runtime state (`env`, logs, PID, model cache) lives in `~/.clauden/` and is never part of the repo.

---

## License

MIT. See [LICENSE](LICENSE).
