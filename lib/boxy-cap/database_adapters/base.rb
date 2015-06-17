require 'rake'
module DatabaseAdapters
  class Base
    require_relative 'mysql'
    require_relative 'postgresql'
    require_relative 'sql_server'

    include FileUtils

    class << self
      def for(config, database_name)
        case config[:adapter]
          when /mysql/
            MySQL.new(config, database_name)
          when 'postgresql', 'pg'
            PostgreSQL.new(config, database_name)
          when 'sqlserver'
            SQLServer.new(config, database_name)
          else
            fail "Database #{config[:adapter]} is not supported!"
        end
      end
    end

    def initialize(config, database_name)
      @config = config
      @database_name = database_name
      @backup_file = File.join(backup_dir, "#{database_name}_#{datestamp}.dump")
    end

    def backup
      mkdir_p(backup_dir)
      sh backup_command
      latest_file_name = File.join(backup_dir, "#{database_name}_latest.dump")
      rm latest_file_name if File.exist?(latest_file_name)
      safe_ln backup_file, latest_file_name
    end

    def restore
      sh "#{restore_command} || echo 'done'"
    end

    def cleanup_old_database_dumps
      dumps = FileList.new(File.join(backup_dir, '*.dump')).exclude(/_latest.dump$/)

      if keep_versions > 0 && dumps.count >= keep_versions
        puts "Keep #{keep_versions} dumps"
        files = (dumps - dumps.last(keep_versions))
        if files.any?
          files.each do |f|
            rm_r f
          end
        end
      end
    end

    def kill_connections
      fail 'Subclass must implement!'
    end

    protected

    attr_reader :config, :database_name, :backup_file

    def backup_command
      fail 'Subclass must implement!'
    end

    def restore_command
      fail 'Subclass must implement!'
    end

    private

    def datestamp
      dateformat = ENV['date-format'] || '%Y-%m-%d_%H-%M-%S'
      Time.now.strftime(dateformat)
    end

    def backup_dir
      @_backup_dir ||= ENV['backup-path'] || Rails.root.join('db', 'backups')
    end

    def keep_versions
      @_keep_versions ||= ENV['ROTATE'].to_i
    end
  end
end

