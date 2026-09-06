require_relative 'config_manager'
require_relative 'file_manager'

module MCPManager
    def self.sync_config(agent, mcp_configs, path_resolver)
      return unless mcp_configs.key?(agent)

      mcp_config_path = File.expand_path(mcp_configs[agent])
      mcp_config = path_resolver.mcp_config_for_agent(agent)
      
      if mcp_config_path.end_with?('.json')
        sync_json_config(agent, mcp_config_path, mcp_config, path_resolver)
      elsif mcp_config_path.end_with?('.toml')
        sync_toml_config(agent, mcp_config_path, mcp_config, path_resolver)
      end
    end

    private

    def self.sync_json_config(agent, mcp_config_path, mcp_config, path_resolver)
      agent_config = ConfigManager.load_json_config(mcp_config_path)

      # If gent has no MCP config and agent has MCP servers, seed the agent's
      # active gent MCP file. This keeps older setups working while allowing
      # mcp.<agent>.yaml to hold agent-specific server sets.
      if mcp_config.empty? && agent_config['mcpServers'] && !agent_config['mcpServers'].empty?
        seed_path = path_resolver.mcp_file_for_agent(agent)
        puts "Copying MCP config from #{agent} to #{seed_path}..."
        ConfigManager.save_yaml_config(seed_path, agent_config['mcpServers'])
        mcp_config = agent_config['mcpServers']
      end

      agent_config['mcpServers'] = mcp_config
      ConfigManager.save_json_config(mcp_config_path, agent_config)
      puts "Synced MCP config for #{agent}"
    end

    def self.sync_toml_config(agent, mcp_config_path, mcp_config, path_resolver)
      agent_config = ConfigManager.load_toml_config(mcp_config_path)

      # If gent has no MCP config and agent has MCP servers, seed the agent's
      # active gent MCP file. This keeps older setups working while allowing
      # mcp.<agent>.yaml to hold agent-specific server sets.
      if mcp_config.empty? && agent_config['mcp_servers'] && !agent_config['mcp_servers'].empty?
        seed_path = path_resolver.mcp_file_for_agent(agent)
        puts "Copying MCP config from #{agent} to #{seed_path}..."
        ConfigManager.save_yaml_config(seed_path, agent_config['mcp_servers'])
        mcp_config = agent_config['mcp_servers']
      end

      agent_config['mcp_servers'] = mcp_config
      ConfigManager.save_toml_config(mcp_config_path, agent_config)
      puts "Synced MCP config for #{agent}"
    end

    def self.backup_config(agent, mcp_configs, backup_dir)
      return unless mcp_configs.key?(agent)

      mcp_config_path = File.expand_path(mcp_configs[agent])
      if File.exist?(mcp_config_path)
        mcp_backup_path = File.join(backup_dir, ConfigManager.agent_key(agent), File.basename(mcp_config_path))
        FileManager.copy_file(mcp_config_path, mcp_backup_path)
      end
    end

    def self.restore_config(agent, mcp_configs, backup_dir)
      return unless mcp_configs.key?(agent)

      mcp_config_path = File.expand_path(mcp_configs[agent])
      mcp_backup_path = File.join(backup_dir, ConfigManager.agent_key(agent), File.basename(mcp_config_path))

      if File.exist?(mcp_backup_path)
        FileManager.restore_file(mcp_backup_path, mcp_config_path)
      end
    end
end
