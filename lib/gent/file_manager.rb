require 'fileutils'
require 'pathname'

module FileManager
    def self.create_directories(*paths)
      paths.each { |path| FileUtils.mkdir_p(path) }
    end

    def self.backup_file(source_path, backup_path)
      return unless File.exist?(source_path)
      
      FileUtils.mkdir_p(File.dirname(backup_path))
      
      if File.symlink?(source_path)
        false # Don't backup symlinks
      else
        FileUtils.mv(source_path, backup_path)
        puts "Backed up #{source_path} to #{backup_path}"
        true
      end
    end

    def self.copy_file(source_path, backup_path)
      return unless File.exist?(source_path)
      
      FileUtils.mkdir_p(File.dirname(backup_path))
      FileUtils.cp(source_path, backup_path)
      puts "Backed up #{File.basename(source_path)} to #{backup_path}"
    end

    def self.restore_file(backup_path, target_path)
      if File.exist?(backup_path)
        FileUtils.mv(backup_path, target_path)
        puts "Restored #{backup_path} to #{target_path}"
        true
      else
        false
      end
    end

    def self.create_symlink(source, target)
      FileUtils.mkdir_p(File.dirname(target))
      source_path = Pathname.new(source).expand_path
      target_path = Pathname.new(target).expand_path
      relative_source = source_path.relative_path_from(target_path.dirname)
      File.symlink(relative_source.to_s, target_path.to_s)
      puts "Linked #{target} -> #{relative_source}"
    end

    def self.remove_symlink(path)
      if File.symlink?(path)
        File.unlink(path)
        puts "Removed symlink #{path}"
        true
      else
        false
      end
    end

    def self.copy_if_conditions_met(source, target, conditions)
      if conditions[:source_exists] && File.exist?(source) &&
         conditions[:target_exists] && File.exist?(target) &&
         conditions[:source_has_content] && File.size(source) > 0 &&
         conditions[:target_is_empty] && File.size(target) == 0

        puts "Copying #{File.basename(source)} config to central rules file..."
        FileUtils.cp(source, target)
        true
      else
        false
      end
    end

    def self.check_existing_symlink(path)
      return nil unless File.exist?(path)
      return nil unless File.symlink?(path)
      
      current_target = File.readlink(path)
      {
        path: path,
        target: current_target,
        message: "#{path} is already a symlink pointing to #{current_target}"
      }
    end

    def self.touch_file(path)
      unless File.exist?(path)
        FileUtils.touch(path)
        puts "Created #{path}"
      end
    end
end
