# Gent

A Ruby CLI tool for centralized AI agent configuration management.

## Overview

Gent solves the problem of managing duplicate configuration files across multiple AI tools. Instead of copy-pasting rules and settings between Claude, Codex, Windsurf, and other agents, gent creates a single source of truth that can be linked to all your AI tools.

## Features

- **Centralized config management** - One config file, linked to multiple agents
- **MCP server synchronization** - Manage shared and agent-specific MCP (Model Context Protocol) servers
- **Multi-format support** - Handles JSON (Claude), TOML (Codex), and Markdown configs
- **Global and project-level configs** - Support for both system-wide and project-specific rules
- **Smart linking** - Safely backs up original configs before creating symlinks
- **Multiple agent support** - Currently supports Claude Code, Codex, Windsurf, and Pi
- **Shared skills directory** - Centralize Claude/Codex/Pi skills into a single source of truth
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
    MCP:       ~/.codex/config.toml           (synced -> /Users/you/.config/gent/mcp.yaml, /Users/you/.config/gent/mcp.codex.yaml)
  windsurf     ~/.codeium/windsurf/memories/global_rules.md (linked -> /Users/you/.config/gent/rules.md)
  pi           ~/.pi/agent/AGENTS.md          (linked -> /Users/you/.config/gent/rules.md)
    MCP:       ~/.pi/agent/mcp.json           (synced -> /Users/you/.config/gent/mcp.yaml)
    Skills:    ~/.pi/agent/skills             (linked -> /Users/you/.config/gent/skills)

Gent MCP configs:
  /Users/you/.config/gent/mcp.yaml          (2 MCP servers)
  /Users/you/.config/gent/mcp.codex.yaml    (1 MCP server)
```

## Usage

```bash
# Link all agents to centralized config (rules + skills)
gent init

# Link specific agent (text configs + MCP servers)  
gent link claude
gent link codex
gent link windsurf
gent link pi

# Unlink specific agent (restores originals)
gent unlink claude

# Use global configs (stored in ~/.config/gent/)
gent init --global
gent link claude --global

# View current linking status, MCP sync info, and skills status
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
  pi: "AGENTS.md"

global_configs:
  "claude code": "~/.claude/CLAUDE.md"
  codex: "~/.codex/AGENTS.md"
  windsurf: "~/.codeium/windsurf/memories/global_rules.md"
  pi: "~/.pi/agent/AGENTS.md"

gent_dirs:
  local: ".gent/rules.md"
  global: "~/.config/gent/rules.md"

# MCP (Model Context Protocol) server configs
mcp_configs:
  "claude code": "~/.claude.json"
  codex: "~/.codex/config.toml"
  pi: "~/.pi/agent/mcp.json"

gent_mcp_dirs:
  local: ".gent/mcp.yaml"
  global: "~/.config/gent/mcp.yaml"

# Skills directory sharing
skill_dirs:
  local:
    "claude code": ".claude/skills"
    codex: ".codex/skills"
    pi: ".pi/skills"
  global:
    "claude code": "~/.claude/skills"
    codex: "~/.codex/skills"
    pi: "~/.pi/agent/skills"

gent_skill_dirs:
  local: ".gent/skills"
  global: "~/.config/gent/skills"
```

## How it Works

### Text Config Management
1. **Backup**: Original agent configs are safely backed up to `original_configs/<agent>/`
2. **Link**: Agent config files are replaced with symlinks to your centralized gent config
3. **Sync**: All linked agents automatically use the same rules and settings

### MCP Server Management
1. **Extract**: MCP servers from agent configs are copied to the active gent MCP file if gent has no MCP config yet
2. **Share**: Servers in `mcp.yaml` are synced to every MCP-capable agent
3. **Specialize**: Optional files such as `mcp.codex.yaml` or `mcp.claude.yaml` are merged into only that agent's MCP config
4. **Format Preservation**: JSON (Claude) and TOML (Codex) formats are maintained
5. **Restore**: Original MCP configs are restored when unlinking

### Skills Directory Sharing
1. **Seed**: If the central skills directory is empty, gent copies existing Claude skills into it
2. **Link**: Agent skill directories are replaced with symlinks to the central skills directory
3. **Restore**: Original skill directories are restored when unlinking

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

**Pi (JSON)**: `~/.pi/agent/mcp.json`
```json
{
  "mcpServers": {
    "puppeteer": {
      "command": "node",
      "args": ["/path/to/server.js"]
    }
  }
}
```

**Shared (YAML)**: `~/.config/gent/mcp.yaml`
```yaml
puppeteer:
  type: stdio
  command: node
  args: ["/path/to/server.js"]
```

**Agent-specific (YAML)**: `~/.config/gent/mcp.codex.yaml`
```yaml
project-tools:
  command: python
  args: ["/path/to/codex-only-server.py"]
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
