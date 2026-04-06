# claude-statusline

A custom status line for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI that displays real-time session info with color-coded indicators.

```
Opus 4.6 │ MED │ ●●○○○○○○○○ 17% │ in24K out3K │ +42 -8 │ ⏱ 3m │ $0.52
```

## What it shows

| Section | Description |
|---------|-------------|
| **Model** | Current model name (blue) |
| **Effort** | Thinking effort level — MAX (red) / HIGH (orange) / MED (yellow) / LOW (green) |
| **Context** | Context window usage with progress bar, color shifts at 50% / 70% / 90% |
| **Tokens** | Input and output token counts (auto-scales to K/M) |
| **Lines** | Lines added/removed (only shown when > 0) |
| **Duration** | Session time elapsed |
| **Cost** | Running USD cost |
| **Rate limit** | 5-hour rate limit usage (only shown when available) |

## Setup

### macOS / Linux

1. Copy `statusline.sh` to `~/.claude/`:

```bash
cp statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
```

2. Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline.sh"
  }
}
```

### Windows (PowerShell)

1. Copy `statusline.ps1` to `%USERPROFILE%\.claude\`:

```powershell
Copy-Item statusline.ps1 "$env:USERPROFILE\.claude\statusline.ps1"
```

2. Add to `%USERPROFILE%\.claude\settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell -NoProfile -File \"%USERPROFILE%\\.claude\\statusline.ps1\""
  }
}
```

> **Note:** The PowerShell version requires Windows Terminal or another terminal with ANSI color support. The legacy `cmd.exe` console does not support RGB colors.

### Dependencies

- **macOS/Linux:** `jq` (JSON parser) — install via `brew install jq` / `apt install jq`
- **Windows:** No extra dependencies (uses PowerShell's built-in `ConvertFrom-Json`)

## Customization

### Project name detection

The status line auto-detects project names when you're inside certain directories. Edit the `projectDirs` list in the script to match your workspace layout:

**Bash:**
```bash
for dir in "$HOME/Desktop" "$HOME/Projects" "$HOME/Documents" "$HOME/Developer"; do
```

**PowerShell:**
```powershell
$projectDirs = @(
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Projects"
)
```

### Colors

All colors use RGB true color (`\033[38;2;R;G;Bm`). Edit the color variables at the top of the script to match your terminal theme.

## Screenshot

```
MYPROJECT │ Opus 4.6 │ MED │ ●●●●●○○○○○ 47% │ in156K out12K │ +120 -34 │ ⏱ 12m │ $2.18
                                  ↑ context bar turns orange at 50%
```

## License

MIT
