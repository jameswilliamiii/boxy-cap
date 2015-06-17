module DatabaseAdapters
  class SQLServer
    def initialize(*)
    end

    def backup
      puts 'Not supported'
    end

    def restore
      puts 'Not supported'
    end

    def kill_connections
      puts 'Not supported'
    end

    def cleanup_old_database_dumps
      puts 'Not supported'
    end
  end
end

