require 'fileutils'
require 'pathname'
require 'yaml'

class Gent
  def self.load_config
    config_file = File.join(__dir__, '..', 'config', 'config.yml')
    YAML.load_file(config_file)
  rescue Errno::ENOENT
    puts "Error: config.yml not found"
    exit 1
  end

  CONFIG = load_config.freeze
  LOCAL_AGENT_CONFIGS = CONFIG['local_configs'].freeze
  GLOBAL_AGENT_CONFIGS = CONFIG['global_configs'].freeze

  def initialize
    @global = false
  end

  def run(args)
    parse_args(args)
    
    case @command
    when 'init'
      init_all_agents
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

  def gent_dir
    File.dirname(rules_file)
  end

  def backup_dir
    File.join(gent_dir, 'original_configs')
  end

  def rules_file
    path = @global ? CONFIG['gent_dirs']['global'] : CONFIG['gent_dirs']['local']
    File.expand_path(path)
  end

  def agent_configs
    @global ? GLOBAL_AGENT_CONFIGS : LOCAL_AGENT_CONFIGS
  end

  def resolve_alias(agent)
    # Handle aliases
    case agent
    when 'claude'
      'claude code'
    else
      agent
    end
  end

  def link_agent(agent)
    # Handle aliases
    agent = resolve_alias(agent)
    
    unless agent_configs.key?(agent)
      puts "Unknown agent: #{agent}"
      puts "Available agents: #{agent_configs.keys.join(', ')}"
      return
    end

    config_path = File.expand_path(agent_configs[agent])
    original_filename = File.basename(agent_configs[agent])
    backup_path = File.join(backup_dir, original_filename)

    # Create directories
    FileUtils.mkdir_p(gent_dir)
    FileUtils.mkdir_p(backup_dir)

    # Create default rules file if it doesn't exist
    unless File.exist?(rules_file)
      FileUtils.touch(rules_file)
      puts "Created #{rules_file}"
    end

    # Handle existing files/symlinks
    if File.exist?(config_path)
      if File.symlink?(config_path)
        current_target = File.readlink(config_path)
        puts "#{config_path} is already a symlink pointing to #{current_target}"
        puts "Run 'gent unlink #{agent}#{@global ? ' --global' : ''}' first to remove it"
        return
      else
        # If gent rules file is empty and agent config has content, copy it
        if File.exist?(rules_file) && File.size(config_path) > 0 && File.size(rules_file) == 0
          puts "Copying #{agent} config to central rules file..."
          FileUtils.cp(config_path, rules_file)
        end
        
        FileUtils.mv(config_path, backup_path)
        puts "Backed up #{config_path} to #{backup_path}"
      end
    end

    # Create parent directory for config if needed
    FileUtils.mkdir_p(File.dirname(config_path))

    # Create symlink
    File.symlink(File.expand_path(rules_file), config_path)
    puts "Linked #{config_path} -> #{rules_file}"
  end

  def unlink_agent(agent)
    # Handle aliases
    agent = resolve_alias(agent)
    
    unless agent_configs.key?(agent)
      puts "Unknown agent: #{agent}"
      return
    end

    config_path = File.expand_path(agent_configs[agent])
    original_filename = File.basename(agent_configs[agent])
    backup_path = File.join(backup_dir, original_filename)

    # Remove symlink if it exists
    if File.symlink?(config_path)
      File.unlink(config_path)
      puts "Removed symlink #{config_path}"
    end

    # Restore backup if it exists
    if File.exist?(backup_path)
      FileUtils.mv(backup_path, config_path)
      puts "Restored #{backup_path} to #{config_path}"
    else
      # No backup, copy the central rules file
      if File.exist?(rules_file)
        FileUtils.cp(rules_file, config_path)
        puts "Copied #{rules_file} to #{config_path}"
      else
        puts "No backup found and no central rules file exists"
      end
    end
  end

  def init_all_agents
    puts "Linking all agents..."
    agent_configs.keys.each do |agent|
      puts "\n--- #{agent.capitalize} ---"
      link_agent(agent)
    end
    puts "\nAll agents linked!"
  end

  def list_agents
    puts "Supported agents:"
    puts
    agent_configs.each do |agent, path|
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
    end
  end

  def show_help
    puts <<~HELP
      gent - Configuration management for AI development tools

      Usage:
        gent init [--global]             Link all agents to central rules
        gent link <agent> [--global]     Link agent config to central rules
        gent unlink <agent> [--global]   Restore agent's original config
        gent list [--global]             Show all supported agents and their status

      Agents:
        #{LOCAL_AGENT_CONFIGS.keys.join(', ')}

      Options:
        --global    Use global config (~/.config/gent) instead of local (.gent)

      Examples:
        gent link claude
        gent unlink claude --global
    HELP
  end
end

