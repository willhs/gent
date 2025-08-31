# Gent Project Context

Gent is a working Ruby CLI tool for centralized AI tool configuration management. 

**Current capabilities:**
- `gent link <agent>` / `gent unlink <agent>` - Link/unlink individual agents
- `gent init` - Link all agents at once  
- `--global` flag for global vs local configs
- YAML config in `config/config.yml` defines agent paths
- Proper gem structure with `bin/`, `lib/`, `config/`
- Smart config copying when gent rules file is empty

**File structure:**
```
bin/gent              # Executable
lib/gent.rb          # Main Ruby class
config/config.yml    # Agent configuration paths  
gent.gemspec         # Gem specification
```

**Agent paths configured:**
- Local: claude=`CLAUDE.md`, codex=`AGENTS.md`, windsurf=`.windsurfrules`
- Global: claude=`~/.claude/CLAUDE.md`, codex=`~/.codex/AGENTS.md`, windsurf=`~/.windsurf/rules.md`
- Gent storage: local=`.gent/rules.md`, global=`~/.config/gent/rules.md`

**Development workflow:**
- Run with `gent` - assume this is a likely a binary already included in the PATH on this machine that links directly to source
  - Otherwise run with bin/gent
- Test changes immediately (no rebuild needed)

**Key implementation details:**
- Uses Ruby's `File.symlink()` for linking configs
- Backs up originals to `.gent/original_configs/` with preserved filenames
- Smart detection of existing symlinks with helpful error messages
- YAML config structure allows easy addition of new agents without code changes
- Uses `__dir__` for relative path resolution in gem structure

**Testing approach:**
- Test with existing config files in `~/projects/deep-footsteps/`
- Verify symlink creation with `ls -la ~/.claude/CLAUDE.md`
- Check backup preservation and restore functionality
- Test both local and global modes

**Ruby learning notes:**
- This is a Ruby learning project - prefer idiomatic Ruby solutions
- Uses proper gem structure but can run without installation
- File operations use Ruby stdlib (`FileUtils`, `File`, `Pathname`)
- YAML loading with error handling for missing config

---

