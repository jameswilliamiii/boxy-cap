module DatabaseAdapters
  class PostgreSQL < Base
    def kill_connections
      kill_postgres_connections
    end

    protected

    def backup_command
      postgres_dump_command
    end

    def restore_command
      postgres_restore_command
    end

    private

    def postgres_dump_command
      result = "#{postgres_password} pg_dump #{database_name} -w -F c"
      result += postgres_auth_options
      result + " > #{backup_file}"
    end

    def postgres_password
      "PGPASSWORD='#{config[:password]}'" if config[:password].present?
    end

    def postgres_auth_options
      command_options = ''
      command_options += " -h #{config[:host]}" if config[:host].present?
      command_options += " -U #{config[:username]}" if config[:username].present?
      command_options
    end

    def postgres_restore_command
      result = "#{postgres_password} pg_restore -d #{database_name} -F c -w #{latest_backup_file}"
      result += postgres_auth_options
      result + ' -O -c'
    end

    def kill_postgres_connections
      pid_column_name = if ActiveRecord::Base.connection.send(:postgresql_version) > 90200
                          'pid'
                        else
                          'procpid'
                        end

      kill_query = <<-QUERY
      SELECT pg_terminate_backend(#{pid_column_name})
      FROM pg_stat_activity
      WHERE datname = '#{database_name}' and pid <> pg_backend_pid() ;
      QUERY

      begin
        ActiveRecord::Base.connection.exec_query(kill_query)
      rescue ActiveRecord::StatementInvalid => ex
        puts "All connections to #{database_name} were killed successfully!"
        puts "Database message: #{ex.message}"
      end
    end
  end
end
