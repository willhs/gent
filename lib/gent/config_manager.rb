require 'yaml'
require 'json'
require 'fileutils'
require 'toml-rb'

module ConfigManager
    def self.load_main_config
      config_file = File.join(__dir__, '..', '..', 'config', 'config.yml')
      YAML.load_file(config_file)
    rescue Errno::ENOENT
      puts "Error: config.yml not found"
      exit 1
    end

    def self.load_json_config(path)
      return {} unless File.exist?(path)
      JSON.parse(File.read(path))
    rescue JSON::ParserError
      {}
    end

    def self.save_json_config(path, config)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, JSON.pretty_generate(config))
    end

    def self.load_yaml_config(path)
      return {} unless File.exist?(path)
      YAML.load_file(path) || {}
    rescue Psych::SyntaxError
      {}
    end

    def self.save_yaml_config(path, config)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, YAML.dump(config))
    end

    def self.load_toml_config(path)
      return {} unless File.exist?(path)
      TomlRB.load_file(path)
    rescue => e
      {}
    end

    def self.save_toml_config(path, config)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, TomlRB.dump(config))
    end

    # Normalized agent name for per-agent directories (e.g. 'claude code' -> 'claude_code')
    def self.agent_key(agent)
      agent.to_s.downcase.gsub(/\s+/, '_')
    end

    class PathResolver
      def initialize(config, global: false)
        @config = config
        @global = global
      end

      def rules_file
        path = @global ? @config['gent_dirs']['global'] : @config['gent_dirs']['local']
        File.expand_path(path)
      end

      # Get agent-specific rules file if it exists (global only), otherwise base rules file
      def rules_file_for_agent(agent)
        if @global
          base_rules = rules_file
          dir = File.dirname(base_rules)
          ext = File.extname(base_rules)
          basename = File.basename(base_rules, ext)

          override_path = File.join(dir, "#{basename}.#{agent_key(agent)}#{ext}")

          if File.exist?(override_path)
            override_path
          else
            base_rules
          end
        else
          rules_file
        end
      end

      def mcp_file
        path = @global ? @config['gent_mcp_dirs']['global'] : @config['gent_mcp_dirs']['local']
        File.expand_path(path)
      end

      def mcp_file_for_agent(agent)
        agent_file = agent_specific_mcp_file(agent)
        File.exist?(agent_file) ? agent_file : mcp_file
      end

      def mcp_files_for_agent(agent)
        files = [mcp_file]
        agent_file = agent_specific_mcp_file(agent)
        files << agent_file if File.exist?(agent_file)
        files
      end

      def mcp_config_for_agent(agent)
        mcp_files_for_agent(agent).each_with_object({}) do |file, config|
          config.merge!(ConfigManager.load_yaml_config(file))
        end
      end

      def agent_specific_mcp_file(agent)
        base_mcp = mcp_file
        dir = File.dirname(base_mcp)
        ext = File.extname(base_mcp)
        basename = File.basename(base_mcp, ext)
        File.join(dir, "#{basename}.#{agent_key(agent)}#{ext}")
      end

      def skills_dir
        path = @global ? @config['gent_skill_dirs']['global'] : @config['gent_skill_dirs']['local']
        File.expand_path(path)
      end

      def gent_dir
        File.dirname(rules_file)
      end

      def backup_dir
        File.join(gent_dir, 'original_configs')
      end

      def agent_configs
        @global ? @config['global_configs'] : @config['local_configs']
      end

      def agent_skill_dirs
        skill_dirs = @config['skill_dirs'] || {}
        scope = @global ? 'global' : 'local'
        skill_dirs[scope] || {}
      end

      private

      def agent_key(agent)
        agent.gsub(/\s+/, '_').downcase.split('_').first
      end
    end
end
