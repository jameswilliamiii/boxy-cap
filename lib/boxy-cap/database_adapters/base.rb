require 'rake'
require 'date'
require 'fileutils'

module Enumerable
  def older_than_days(days)
    now = Date.today
    each do |file|
      yield file if (now - File.stat(file).mtime.to_date) > days.days
    end
  end
end

module DatabaseAdapters
  class Base
    require_relative 'mysql'
    require_relative 'postgresql'
    require_relative 'sql_server'

    include FileUtils
    include Enumerable
    
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
      @latest_backup_file = File.join(backup_dir, "#{database_name}_latest.dump")
    end

    def backup
      mkdir_p(backup_dir)
      sh backup_command
      rm latest_backup_file if File.exist?(latest_backup_file)
      safe_ln backup_file, latest_backup_file
    end

    def restore
      sh "#{restore_command} || echo 'done'"
    end

    def cleanup_old_database_dumps
      num_of_days=db_retention
       
      dumps = FileList.new(File.join(backup_dir, '*.dump')).exclude(/_latest.dump$/)
      Dir.glob(dumps).older_than_days(num_of_days) do |file|
          FileUtils.rm(file) if File.file?(file)
      end
    end

    def kill_connections
      fail 'Subclass must implement!'
    end

    protected

    attr_reader :config, :database_name, :backup_file, :latest_backup_file

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
    
    def db_retention
      @_db_retention ||= ENV['NO_OF_DAYS'].to_i
    end
  end
end
