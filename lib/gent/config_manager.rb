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

          # Normalize agent name (e.g., "claude code" -> "claude")
          agent_key = agent.gsub(/\s+/, '_').downcase.split('_').first
          override_path = File.join(dir, "#{basename}.#{agent_key}#{ext}")

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

      def gent_dir
        File.dirname(rules_file)
      end

      def backup_dir
        File.join(gent_dir, 'original_configs')
      end

      def agent_configs
        @global ? @config['global_configs'] : @config['local_configs']
      end
    end
end