# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Gent is a configuration management tool designed to centralize settings for various development tools (Claude, Claude Code, Codex, Windsurf). This is also a Ruby learning project for the author.

## Project Status

This is an early-stage project with minimal codebase - currently only contains a README.md file. The project hasn't been initialized with Ruby files, Gemfile, or any code structure yet.

## Architecture Goals

Based on the README, the project aims to provide:
- Centralized configuration for AI development tools
- Support for both global and project-level configurations
- Configuration types: rules (prompt extensions), MCP servers, workflows/commands, and future agents

## Development Commands

Since this is a Ruby project in early stages, standard Ruby development commands will likely be:
- `bundle install` - Install dependencies (once Gemfile is created)
- `ruby <script>.rb` - Run Ruby scripts
- `rake <task>` - Run Rake tasks (if Rakefile exists)
- `rspec` or similar - Run tests (once test framework is chosen)

## Notes for Future Development

- This is explicitly a Ruby learning project, so prefer Ruby idiomatic solutions
- No build system, package manager, or code structure exists yet
- The project will need initialization with proper Ruby project structure
- Consider adding Gemfile, lib/ directory, and test framework as next steps