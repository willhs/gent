require 'yaml'
require 'json'
require 'fileutils'

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

    class PathResolver
      def initialize(config, global: false)
        @config = config
        @global = global
      end

      def rules_file
        path = @global ? @config['gent_dirs']['global'] : @config['gent_dirs']['local']
        File.expand_path(path)
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