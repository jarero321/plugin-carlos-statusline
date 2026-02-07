<img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=0,2,5,30&height=180&section=header&text=claude-plugin-statusline&fontSize=32&fontColor=fff&animation=fadeIn&fontAlignY=32" />

<div align="center">

![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Claude Code](https://img.shields.io/badge/Claude_Code-Plugin-7c3aed?style=for-the-badge)
![Dependencies](https://img.shields.io/badge/dependencies-0-00d4ff?style=for-the-badge)
![License](https://img.shields.io/github/license/jarero321/plugin-carlos-statusline?style=for-the-badge)

**DX-first statusline for Claude Code with ANSI progress bars, context metrics, cost tracking, and git info.**

<a href="https://github.com/jarero321/plugin-carlos-statusline">
  <img src="https://img.shields.io/badge/CODE-2ea44f?style=for-the-badge&logo=github&logoColor=white" alt="code" />
</a>

[Features](#features) •
[Installation](#installation) •
[How It Works](#how-it-works) •
[Configuration](#configuration) •
[Extensibility](#extensibility)

</div>

---

### Preview

```
[Opus 4.6] │ [━━━╸──] 48% │ [━━━──] 62% │ [━╸────] 18% │ Pro │ +142/-38 │ 🟦 TS │ 🌿 main │ $1.25 │ 3m
```

## Features

| Feature | Description |
|:--------|:------------|
| **Model Detection** | Color-coded model display (Cyan=Opus, Green=Sonnet, Yellow=Haiku) |
| **Context Progress Bar** | 7-char ANSI bar with dynamic colors based on usage |
| **Session & Weekly Limits** | Visual bars for rate limit tracking |
| **Cost Tracking** | Accumulated cost in USD with color thresholds |
| **Git Integration** | Branch detection + open PR count via `gh` |
| **Language Detection** | Auto-detect 13+ languages by marker files |
| **Line Changes** | Green additions / red removals counter |
| **Agent Mode** | Shows active agent name when in subagent context |
| **Zero Dependencies** | Pure Bash — no jq, no node, no python |

## Tech Stack

<div align="center">

**Powered By**

<img src="https://skillicons.dev/icons?i=bash,git,github&perline=8" alt="tech" />

</div>

---

## Installation

### Prerequisites

- Claude Code CLI installed
- Bash 4.0+
- Git (optional, for branch detection)

### Setup

```bash
# 1. Clone the plugin to plugins directory
mkdir -p ~/.claude/plugins/carlos-statusline
cp -r . ~/.claude/plugins/carlos-statusline/

# 2. Make it executable
chmod +x ~/.claude/plugins/carlos-statusline/scripts/statusline.sh

# 3. Configure in settings.json
```

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/home/USER/.claude/plugins/carlos-statusline/scripts/statusline.sh",
    "padding": 0
  }
}
```

Restart Claude Code to activate.

> Or use the built-in setup skill: the plugin includes `commands/statusline-setup.md` that automates configuration.

---

## How It Works

The plugin operates as a **stdin processor**. Claude Code invokes the configured command and pipes a JSON payload with the current session state.

```
Claude Code (JSON stdin) ──▶ statusline.sh ──▶ ANSI output (stdout)
```

### Input JSON (example)

```json
{
  "model": { "display_name": "Opus 4.6" },
  "workspace": { "current_dir": "/home/carlos/my-project" },
  "cost": {
    "total_cost_usd": 1.25,
    "total_lines_added": 142,
    "total_lines_removed": 38
  },
  "context_window": { "used_percentage": 48.3 }
}
```

### Processing Pipeline

1. **Read**: Full JSON from stdin
2. **Parse**: Custom `grep -oP` extractor (no jq needed)
3. **Detect**: Git branch, language, plan tier, agent mode
4. **Render**: ANSI-formatted statusline to stdout (no trailing newline)

---

## Architecture

```
claude-plugin-statusline/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata (name, version, author)
├── commands/
│   └── statusline-setup.md  # Setup automation skill for Claude
├── scripts/
│   └── statusline.sh        # Core script (286 lines)
└── README.md
```

| File | Responsibility |
|:-----|:---------------|
| `plugin.json` | Declares the plugin to Claude Code ecosystem |
| `statusline-setup.md` | Skill that automates settings.json configuration |
| `statusline.sh` | Core: JSON parsing, rendering logic, ANSI output |

### Design Decisions

| Decision | Reason |
|:---------|:-------|
| **Pure Bash** | Zero dependencies, available on any Unix system |
| **No jq** | Eliminates external tooling requirement |
| **`grep -oP`** | Lightweight parser with nested key support |
| **ANSI codes** | Maximum compatibility with modern terminals |
| **`echo -en`** | No trailing newline — Claude Code controls layout |

---

## Configuration

### Progress Bar Thresholds

| Context Usage | Color | Meaning |
|:--------------|:------|:--------|
| < 50% | Green | Healthy usage |
| 50% - 74% | Yellow | Moderate usage |
| >= 75% | Red | Context almost full |

### Cost Thresholds

| Cost | Color | Meaning |
|:-----|:------|:--------|
| < $2 | White | Normal |
| $2 - $5 | Yellow | Moderate |
| >= $5 | Red | High spend |

### Language Detection

| Language | Marker File |
|:---------|:------------|
| Go | `go.mod` |
| TypeScript | `tsconfig.json` |
| JavaScript | `package.json` |
| Rust | `Cargo.toml` |
| Python | `pyproject.toml`, `requirements.txt` |
| PHP | `composer.json` |
| Ruby | `Gemfile` |
| C# | `.csproj`, `.sln` |
| Java | `pom.xml`, `build.gradle` |
| Dart | `pubspec.yaml` |
| Elixir | `mix.exs` |
| Swift | `Package.swift` |
| C/C++ | `CMakeLists.txt`, `Makefile` |

### Optional Config File

Create `~/.config/carlos-statusline/config`:

```bash
USAGE_CACHE_TTL=300
SHOW_GIT=true
SHOW_COST=true
SHOW_LINES=true
BAR_WIDTH=6
THEME="default"
```

---

## Extensibility

### Add New Segments

Each statusline segment is independent:

```bash
# Extract value from JSON
my_value=$(jval "new_key" "default")

# Append to output
output+=" ${SEP} ${my_value}"
```

### Script Variants

Create multiple scripts and switch in `settings.json`:

```
scripts/
├── statusline.sh          # Default: full
├── statusline-minimal.sh  # Model + context only
└── statusline-git.sh      # Git-focused metrics
```

### Theme Support

| Theme | Folder | Git | Separator |
|:------|:-------|:----|:----------|
| `default` | folder icon | branch icon | `│` |
| `nerd-fonts` | nerd icon | nerd icon | `│` |
| `ascii` | `DIR:` | `BR:` | `\|` |
| `minimal` | *(hidden)* | *(hidden)* | ` ` |

---

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**[Report Bug](https://github.com/jarero321/plugin-carlos-statusline/issues)** · **[Request Feature](https://github.com/jarero321/plugin-carlos-statusline/issues)**

</div>

<img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=0,2,5,30&height=120&section=footer" />
