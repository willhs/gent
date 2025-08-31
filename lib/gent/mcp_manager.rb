require_relative 'config_manager'
require_relative 'file_manager'

module MCPManager
    def self.sync_config(agent, mcp_configs, path_resolver)
      return unless mcp_configs.key?(agent)

      mcp_config_path = File.expand_path(mcp_configs[agent])
      central_mcp = ConfigManager.load_yaml_config(path_resolver.mcp_file)
      
      if mcp_config_path.end_with?('.json')
        sync_json_config(agent, mcp_config_path, central_mcp, path_resolver)
      elsif mcp_config_path.end_with?('.toml')
        sync_toml_config(agent, mcp_config_path, central_mcp, path_resolver)
      end
    end

    private

    def self.sync_json_config(agent, mcp_config_path, central_mcp, path_resolver)
      agent_config = ConfigManager.load_json_config(mcp_config_path)

      # If central MCP is empty and agent has MCP servers, steal them
      if central_mcp.empty? && agent_config['mcpServers'] && !agent_config['mcpServers'].empty?
        puts "Copying MCP config from #{agent} to central config..."
        ConfigManager.save_yaml_config(path_resolver.mcp_file, agent_config['mcpServers'])
        central_mcp = agent_config['mcpServers']
      end

      # Update agent config to use central MCP servers
      agent_config['mcpServers'] = central_mcp
      ConfigManager.save_json_config(mcp_config_path, agent_config)
      puts "Synced MCP config for #{agent}"
    end

    def self.sync_toml_config(agent, mcp_config_path, central_mcp, path_resolver)
      agent_config = ConfigManager.load_toml_config(mcp_config_path)

      # If central MCP is empty and agent has MCP servers, steal them  
      if central_mcp.empty? && agent_config['mcp_servers'] && !agent_config['mcp_servers'].empty?
        puts "Copying MCP config from #{agent} to central config..."
        ConfigManager.save_yaml_config(path_resolver.mcp_file, agent_config['mcp_servers'])
        central_mcp = agent_config['mcp_servers']
      end

      # Update agent config to use central MCP servers
      agent_config['mcp_servers'] = central_mcp
      ConfigManager.save_toml_config(mcp_config_path, agent_config)
      puts "Synced MCP config for #{agent}"
    end

    def self.backup_config(agent, mcp_configs, backup_dir)
      return unless mcp_configs.key?(agent)
      
      mcp_config_path = File.expand_path(mcp_configs[agent])
      if File.exist?(mcp_config_path)
        mcp_backup_path = File.join(backup_dir, File.basename(mcp_config_path))
        FileManager.copy_file(mcp_config_path, mcp_backup_path)
      end
    end

    def self.restore_config(agent, mcp_configs, backup_dir)
      return unless mcp_configs.key?(agent)
      
      mcp_config_path = File.expand_path(mcp_configs[agent])
      mcp_backup_path = File.join(backup_dir, File.basename(mcp_config_path))
      
      if File.exist?(mcp_backup_path)
        FileManager.restore_file(mcp_backup_path, mcp_config_path)
      end
    end
end