require 'fileutils'
require 'pathname'
require_relative 'file_manager'
require_relative 'mcp_manager'
require_relative 'skills_manager'

module AgentManager
    def self.resolve_alias(agent)
      case agent
      when 'claude'
        'claude code'
      else
        agent
      end
    end

    def self.link(agent, path_resolver, mcp_configs, global: false)
      agent = resolve_alias(agent)

      unless path_resolver.agent_configs.key?(agent)
        puts "Unknown agent: #{agent}"
        puts "Available agents: #{path_resolver.agent_configs.keys.join(', ')}"
        return false
      end

      config_path = File.expand_path(path_resolver.agent_configs[agent])
      original_filename = File.basename(path_resolver.agent_configs[agent])
      backup_path = File.join(path_resolver.backup_dir, original_filename)

      # Create directories
      FileManager.create_directories(path_resolver.gent_dir, path_resolver.backup_dir)

      # Create default rules file if it doesn't exist
      FileManager.touch_file(path_resolver.rules_file)

      # Get agent-specific rules file (may be override or base)
      agent_rules_file = path_resolver.rules_file_for_agent(agent)

      # Create agent-specific override file if it doesn't exist (global mode only)
      if global && agent_rules_file != path_resolver.rules_file
        FileManager.touch_file(agent_rules_file)
      end

      # Check for existing symlink
      if symlink_info = FileManager.check_existing_symlink(config_path)
        puts symlink_info[:message]
        puts "Run 'gent unlink #{agent}#{global ? ' --global' : ''}' first to remove it"
        return false
      end

      # Handle existing files
      if File.exist?(config_path)
        # Copy agent config to rules if conditions are met
        FileManager.copy_if_conditions_met(
          config_path,
          agent_rules_file,
          {
            source_exists: true,
            target_exists: true,
            source_has_content: true,
            target_is_empty: true
          }
        )

        FileManager.backup_file(config_path, backup_path)
      end

      # Backup MCP config if this agent supports it and we're in global mode
      if global
        MCPManager.backup_config(agent, mcp_configs, path_resolver.backup_dir)
      end

      # Create symlink to agent-specific rules file
      FileManager.create_symlink(agent_rules_file, config_path)

      # Handle MCP config if this agent supports it and we're in global mode
      if global
        MCPManager.sync_config(agent, mcp_configs, path_resolver)
      end

      SkillsManager.link(agent, path_resolver, global: global)

      true
    end

    def self.unlink(agent, path_resolver, mcp_configs, global: false)
      agent = resolve_alias(agent)
      
      unless path_resolver.agent_configs.key?(agent)
        puts "Unknown agent: #{agent}"
        return false
      end

      config_path = File.expand_path(path_resolver.agent_configs[agent])
      original_filename = File.basename(path_resolver.agent_configs[agent])
      backup_path = File.join(path_resolver.backup_dir, original_filename)

      # Remove symlink if it exists
      FileManager.remove_symlink(config_path)

      # Restore backup if it exists
      unless FileManager.restore_file(backup_path, config_path)
        # No backup, copy the central rules file
        if File.exist?(path_resolver.rules_file)
          FileUtils.cp(path_resolver.rules_file, config_path)
          puts "Copied #{path_resolver.rules_file} to #{config_path}"
        else
          puts "No backup found and no central rules file exists"
        end
      end

      # Restore MCP config backup if this agent supports it and we're in global mode
      if global
        MCPManager.restore_config(agent, mcp_configs, path_resolver.backup_dir)
      end

      SkillsManager.unlink(agent, path_resolver, global: global)

      true
    end

    def self.list(path_resolver, mcp_configs = {})
      puts "Supported agents:"
      puts
      skill_dirs = path_resolver.agent_skill_dirs

      path_resolver.agent_configs.each do |agent, path|
        config_path = File.expand_path(path)
        status = if File.exist?(config_path)
          if File.symlink?(config_path)
            target = File.readlink(config_path)
            "linked -> #{target}"
          else
            "original file"
          end
        else
          "not found"
        end
        puts "  #{agent.ljust(12)} #{path.ljust(30)} (#{status})"

        # Show MCP config if this agent has one
        if mcp_configs.key?(agent)
          mcp_path = mcp_configs[agent]
          mcp_full_path = File.expand_path(mcp_path)
          mcp_status = if File.exist?(mcp_full_path)
            "synced -> #{path_resolver.mcp_file}"
          else
            "not found"
          end
          puts "    MCP:       #{mcp_path.ljust(30)} (#{mcp_status})"
        end

        if skill_dirs.key?(agent)
          skill_path = skill_dirs[agent]
          skill_full_path = File.expand_path(skill_path)
          skill_status = if File.exist?(skill_full_path)
            if File.symlink?(skill_full_path)
              target = File.readlink(skill_full_path)
              "linked -> #{target}"
            else
              "original directory"
            end
          else
            "not found"
          end
          puts "    Skills:    #{skill_path.ljust(30)} (#{skill_status})"
        end
      end

      # Show central MCP config if any agents have MCP support
      if !mcp_configs.empty?
        puts
        puts "Central MCP config:"
        mcp_file = path_resolver.mcp_file
        mcp_status = if File.exist?(mcp_file)
          central_mcp = ConfigManager.load_yaml_config(mcp_file)
          server_count = central_mcp.keys.length
          "#{server_count} MCP server#{'s' if server_count != 1}"
        else
          "not found"
        end
        puts "  #{mcp_file.ljust(42)} (#{mcp_status})"
      end

      if !skill_dirs.empty?
        puts
        puts "Central skills directory:"
        skills_dir = path_resolver.skills_dir
        skills_status = if Dir.exist?(skills_dir)
          skill_count = Dir.children(skills_dir).length
          "#{skill_count} skill#{'s' if skill_count != 1}"
        else
          "not found"
        end
        puts "  #{skills_dir.ljust(42)} (#{skills_status})"
      end
    end

    def self.init_all(path_resolver, mcp_configs, global: false)
      puts "Linking all agents..."
      success_count = 0
      
      path_resolver.agent_configs.keys.each do |agent|
        puts "\n--- #{agent.capitalize} ---"
        if link(agent, path_resolver, mcp_configs, global: global)
          success_count += 1
        end
      end
      
      puts "\n#{success_count} agents linked successfully!"
      true
    end

    def self.sync_all(path_resolver, mcp_configs, global: false)
      puts "Syncing agent configs with gent rules..."
      synced_count = 0
      SkillsManager.seed_central(path_resolver)

      path_resolver.agent_configs.keys.each do |agent|
        puts "\n--- #{agent.capitalize} ---"
        config_path = File.expand_path(path_resolver.agent_configs[agent])

        if File.exist?(config_path) && File.symlink?(config_path)
          target = File.readlink(config_path)
          expected_target = path_resolver.rules_file_for_agent(agent)
          resolved_target = File.expand_path(target, File.dirname(config_path))
          target_is_absolute = Pathname.new(target).absolute?

          if resolved_target == expected_target && !target_is_absolute
            puts "Already synced to #{expected_target}"
          else
            puts "Updating symlink target from #{target} to #{expected_target}"
            FileManager.remove_symlink(config_path)
            FileManager.create_symlink(expected_target, config_path)
          end

          # Sync MCP config if this agent supports it and we're in global mode
          if global
            MCPManager.sync_config(agent, mcp_configs, path_resolver)
          end

          synced_count += 1
        else
          puts "Not linked - use 'gent link #{agent}' to link first"
        end

        SkillsManager.sync(agent, path_resolver, global: global)
      end

      puts "\n#{synced_count} agents synced successfully!"
      true
    end
end
