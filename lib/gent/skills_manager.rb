require 'fileutils'
require_relative 'file_manager'

module SkillsManager
    def self.link(agent, path_resolver, global: false)
      agent_skill_dirs = path_resolver.agent_skill_dirs
      return false unless agent_skill_dirs.key?(agent)

      central_dir = path_resolver.skills_dir
      agent_dir = File.expand_path(agent_skill_dirs[agent])
      backup_dir = File.join(path_resolver.backup_dir, 'skills', normalize_agent(agent))

      FileUtils.mkdir_p(central_dir)
      seed_central_from_agent(agent_dir, central_dir, agent)

      if symlink_info = FileManager.check_existing_symlink(agent_dir)
        puts symlink_info[:message]
        puts "Run 'gent unlink #{agent}#{global ? ' --global' : ''}' first to remove it"
        return false
      end

      if Dir.exist?(agent_dir)
        FileManager.backup_directory(agent_dir, backup_dir)
      end

      FileManager.create_symlink(central_dir, agent_dir)
      true
    end

    def self.unlink(agent, path_resolver, global: false)
      agent_skill_dirs = path_resolver.agent_skill_dirs
      return false unless agent_skill_dirs.key?(agent)

      central_dir = path_resolver.skills_dir
      agent_dir = File.expand_path(agent_skill_dirs[agent])
      backup_dir = File.join(path_resolver.backup_dir, 'skills', normalize_agent(agent))

      FileManager.remove_symlink(agent_dir)

      unless FileManager.restore_directory(backup_dir, agent_dir)
        if Dir.exist?(central_dir)
          copy_directory_contents(central_dir, agent_dir)
          puts "Copied #{central_dir} to #{agent_dir}"
        else
          puts 'No backup found and no central skills directory exists'
        end
      end

      true
    end

    def self.seed_central(path_resolver)
      agent_skill_dirs = path_resolver.agent_skill_dirs
      return false if agent_skill_dirs.empty?

      central_dir = path_resolver.skills_dir
      return false unless directory_empty?(central_dir)

      ordered_seed_sources(agent_skill_dirs).each do |agent, path|
        source_dir = File.expand_path(path)
        next unless Dir.exist?(source_dir)
        next if File.symlink?(source_dir)
        next if directory_empty?(source_dir)

        copy_directory_contents(source_dir, central_dir)
        puts "Seeded central skills from #{agent}"
        return true
      end

      false
    end

    def self.sync(agent, path_resolver, global: false)
      agent_skill_dirs = path_resolver.agent_skill_dirs
      return false unless agent_skill_dirs.key?(agent)

      central_dir = path_resolver.skills_dir
      agent_dir = File.expand_path(agent_skill_dirs[agent])
      backup_dir = File.join(path_resolver.backup_dir, 'skills', normalize_agent(agent))

      FileUtils.mkdir_p(central_dir)

      if File.symlink?(agent_dir)
        target = File.readlink(agent_dir)
        resolved_target = File.expand_path(target, File.dirname(agent_dir))

        if resolved_target == central_dir
          puts "Skills already synced to #{central_dir}"
        else
          puts "Updating skills symlink target from #{target} to #{central_dir}"
          FileManager.remove_symlink(agent_dir)
          FileManager.create_symlink(central_dir, agent_dir)
        end
      else
        if Dir.exist?(agent_dir)
          FileManager.backup_directory(agent_dir, backup_dir)
        end

        FileManager.create_symlink(central_dir, agent_dir)
      end

      true
    end

    def self.sync_all(path_resolver, global: false)
      seed_central(path_resolver)

      agent_skill_dirs = path_resolver.agent_skill_dirs
      agent_skill_dirs.keys.each do |agent|
        sync(agent, path_resolver, global: global)
      end

      true
    end

    private

    def self.normalize_agent(agent)
      agent.to_s.downcase.gsub(/\s+/, '_')
    end

    def self.copy_directory_contents(source_dir, target_dir)
      FileUtils.mkdir_p(target_dir)
      Dir.children(source_dir).each do |entry|
        FileUtils.cp_r(File.join(source_dir, entry), target_dir, preserve: true)
      end
    end

    def self.directory_empty?(path)
      return true unless Dir.exist?(path)

      Dir.children(path).empty?
    end

    def self.seed_central_from_agent(agent_dir, central_dir, agent)
      return unless directory_empty?(central_dir)
      return unless Dir.exist?(agent_dir)
      return if File.symlink?(agent_dir)
      return if directory_empty?(agent_dir)

      copy_directory_contents(agent_dir, central_dir)
      puts "Seeded central skills from #{agent}"
    end

    def self.ordered_seed_sources(agent_skill_dirs)
      sources = []
      if agent_skill_dirs.key?('claude code')
        sources << ['claude code', agent_skill_dirs['claude code']]
      end

      agent_skill_dirs.each do |agent, path|
        next if agent == 'claude code'

        sources << [agent, path]
      end

      sources
    end
end
