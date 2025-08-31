# Gent

A Ruby CLI tool for centralized AI agent configuration management.

## Overview

Gent solves the problem of managing duplicate configuration files across multiple AI tools. Instead of copy-pasting rules and settings between Claude, Codex, Windsurf, and other agents, gent creates a single source of truth that can be linked to all your AI tools.

## Features

- **Centralized config management** - One config file, linked to multiple agents
- **Global and project-level configs** - Support for both system-wide and project-specific rules
- **Smart linking** - Safely backs up original configs before creating symlinks
- **Multiple agent support** - Currently supports Claude, Codex, and Windsurf
- **Easy extensibility** - Add new agents via YAML configuration

## Installation

```bash
# Clone and make executable
git clone https://github.com/willhs/gent.git
cd gent
chmod +x bin/gent
# Add to PATH or run directly with bin/gent
```

## Usage

```bash
# Link all agents to centralized config
gent init

# Link specific agent
gent link claude
gent link codex
gent link windsurf

# Unlink specific agent
gent unlink claude

# Use global configs (stored in ~/.config/gent/)
gent init --global
gent link claude --global
```

## Configuration

Agent paths are defined in `config/config.yml`:

```yaml
agents:
  claude:
    local: "CLAUDE.md"
    global: "~/.claude/CLAUDE.md"
  codex:
    local: "AGENTS.md" 
    global: "~/.codex/AGENTS.md"
  windsurf:
    local: ".windsurfrules"
    global: "~/.windsurf/rules.md"

gent_config:
  local: ".gent/rules.md"
  global: "~/.config/gent/rules.md"
```

## How it Works

1. **Backup**: Original agent configs are safely backed up to `.gent/original_configs/`
2. **Link**: Agent config files are replaced with symlinks to your centralized gent config
3. **Sync**: All linked agents automatically use the same rules and settings

## Project Structure

```
bin/gent              # Executable CLI
lib/gent.rb          # Main Ruby class
config/config.yml    # Agent configuration paths
gent.gemspec         # Gem specification
```

