# Gent

A Ruby CLI tool for centralized AI agent configuration management.

## Overview

Gent solves the problem of managing duplicate configuration files across multiple AI tools. Instead of copy-pasting rules and settings between Claude, Codex, Windsurf, and other agents, gent creates a single source of truth that can be linked to all your AI tools.

## Features

- **Centralized config management** - One config file, linked to multiple agents
- **MCP server synchronization** - Manage MCP (Model Context Protocol) servers centrally
- **Multi-format support** - Handles JSON (Claude), TOML (Codex), and Markdown configs
- **Global and project-level configs** - Support for both system-wide and project-specific rules
- **Smart linking** - Safely backs up original configs before creating symlinks
- **Multiple agent support** - Currently supports Claude Code, Codex, and Windsurf
- **Modular architecture** - Clean, extensible Ruby modules for easy maintenance

## Installation

```bash
# Clone the repository
git clone https://github.com/willhs/gent.git
cd gent

# Install dependencies
bundle install

# Make executable and add to PATH
chmod +x bin/gent
# Add bin/gent to your PATH or create a symlink:
# ln -s $(pwd)/bin/gent /usr/local/bin/gent

gent --help
```

## Example Output

```bash
$ gent list --global
Supported agents:

  claude code  ~/.claude/CLAUDE.md            (linked -> /Users/you/.config/gent/rules.md)
    MCP:       ~/.claude.json                 (synced -> /Users/you/.config/gent/mcp.yaml)
  codex        ~/.codex/AGENTS.md             (linked -> /Users/you/.config/gent/rules.md)
    MCP:       ~/.codex/config.toml           (synced -> /Users/you/.config/gent/mcp.yaml)
  windsurf     ~/.codeium/windsurf/memories/global_rules.md (linked -> /Users/you/.config/gent/rules.md)

Central MCP config:
  /Users/you/.config/gent/mcp.yaml          (2 MCP servers)
```

## Usage

```bash
# Link all agents to centralized config
gent init

# Link specific agent (text configs + MCP servers)  
gent link claude
gent link codex
gent link windsurf

# Unlink specific agent (restores originals)
gent unlink claude

# Use global configs (stored in ~/.config/gent/)
gent init --global
gent link claude --global

# View current linking status and MCP sync info
gent list
gent list --global
```

## Configuration

Agent paths and MCP configs are defined in `config/config.yml`:

```yaml
local_configs:
  "claude code": "CLAUDE.md"
  codex: "AGENTS.md"
  windsurf: ".windsurfrules"

global_configs:
  "claude code": "~/.claude/CLAUDE.md"
  codex: "~/.codex/AGENTS.md"
  windsurf: "~/.codeium/windsurf/memories/global_rules.md"

gent_dirs:
  local: ".gent/rules.md"
  global: "~/.config/gent/rules.md"

# MCP (Model Context Protocol) server configs
mcp_configs:
  "claude code": "~/.claude.json"
  codex: "~/.codex/config.toml"

gent_mcp_dirs:
  local: ".gent/mcp.yaml"
  global: "~/.config/gent/mcp.yaml"
```

## How it Works

### Text Config Management
1. **Backup**: Original agent configs are safely backed up to `.gent/original_configs/`
2. **Link**: Agent config files are replaced with symlinks to your centralized gent config
3. **Sync**: All linked agents automatically use the same rules and settings

### MCP Server Management
1. **Extract**: MCP servers from agent configs are copied to central `mcp.yaml` (if central is empty)
2. **Centralize**: All agents' MCP configs point to the same centralized server definitions
3. **Format Preservation**: JSON (Claude) and TOML (Codex) formats are maintained
4. **Restore**: Original MCP configs are restored when unlinking

## MCP Server Formats

**Claude (JSON)**: `~/.claude.json`
```json
{
  "mcpServers": {
    "puppeteer": {
      "type": "stdio", 
      "command": "node",
      "args": ["/path/to/server.js"]
    }
  }
}
```

**Codex (TOML)**: `~/.codex/config.toml`
```toml
[mcp_servers.puppeteer]
command = "node"
args = ["/path/to/server.js"]
type = "stdio"
```

**Central (YAML)**: `~/.config/gent/mcp.yaml`
```yaml
puppeteer:
  type: stdio
  command: node
  args: ["/path/to/server.js"]
```

## Project Structure

```
bin/gent              # Executable CLI
lib/
├── gent.rb          # Main CLI class
└── gent/
    ├── config_manager.rb    # YAML/JSON/TOML config handling
    ├── file_manager.rb      # File operations & symlinks
    ├── mcp_manager.rb       # MCP server synchronization
    └── agent_manager.rb     # Agent linking/unlinking logic
config/config.yml     # Agent and MCP configuration paths
gent.gemspec         # Gem specification with dependencies
```

