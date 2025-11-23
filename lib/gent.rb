require_relative 'gent/config_manager'
require_relative 'gent/file_manager'
require_relative 'gent/mcp_manager'
require_relative 'gent/agent_manager'

class Gent
  CONFIG = ConfigManager.load_main_config.freeze
  MCP_CONFIGS = CONFIG['mcp_configs']&.freeze || {}

  def initialize
    @global = false
  end

  def run(args)
    parse_args(args)
    
    case @command
    when 'init'
      init_all_agents
    when 'sync'
      sync_all_agents
    when 'link'
      link_agent(@agent)
    when 'unlink'
      unlink_agent(@agent)
    when 'list'
      list_agents
    else
      show_help
    end
  end

  private

  def parse_args(args)
    @global = args.include?('--global')
    args = args.reject { |arg| arg.start_with?('--') }
    
    @command = args[0]
    @agent = args[1]
  end

  def path_resolver
    @path_resolver ||= ConfigManager::PathResolver.new(CONFIG, global: @global)
  end

  def link_agent(agent)
    AgentManager.link(agent, path_resolver, MCP_CONFIGS, global: @global)
  end

  def unlink_agent(agent)
    AgentManager.unlink(agent, path_resolver, MCP_CONFIGS, global: @global)
  end

  def init_all_agents
    AgentManager.init_all(path_resolver, MCP_CONFIGS, global: @global)
  end

  def sync_all_agents
    AgentManager.sync_all(path_resolver, MCP_CONFIGS, global: @global)
  end

  def list_agents
    AgentManager.list(path_resolver, MCP_CONFIGS)
  end

  def show_help
    puts <<~HELP
      gent - Configuration management for AI development tools

      Usage:
        gent init [--global]             Link all agents to central rules
        gent sync [--global]             Sync linked agents with current gent config
        gent link <agent> [--global]     Link agent config to central rules
        gent unlink <agent> [--global]   Restore agent's original config
        gent list [--global]             Show all supported agents and their status

      Agents:
        #{CONFIG['local_configs'].keys.join(', ')}

      Options:
        --global    Use global config (~/.config/gent) instead of local (.gent)

      Examples:
        gent init
        gent sync --global
        gent link claude
        gent unlink claude --global
    HELP
  end
end