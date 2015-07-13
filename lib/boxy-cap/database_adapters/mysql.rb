module DatabaseAdapters
  class MySQL < Base
    def kill_connections
      # no-op. Not implemented for MySQL.
    end

    protected

    def backup_command
      mysql_dump_command
    end

    def restore_command
      mysql_restore_command
    end

    private

    def mysql_dump_command
      result = "mysqldump #{database_name} "
      result += mysql_auth_options
      result + " > #{backup_file}"
    end

    def mysql_restore_command
      "mysql #{database_name} #{mysql_auth_options} < #{latest_backup_file}"
    end

    def mysql_auth_options
      command_options = ''
      command_options += "--password='#{config[:password]}'" if config[:password].present?
      command_options += " -h #{config[:host]}" if config[:host].present?
      command_options += " -u #{config[:username]}" if config[:username].present?
      command_options
    end
  end
end
