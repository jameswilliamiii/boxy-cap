namespace :db do
  require_relative '../database_adapters/base'

  desc 'Backup database'
  task backup: [:environment, :load_config] do
    database_adapter = DatabaseAdapters::Base.for(connection_config, current_database)
    database_adapter.backup
  end

  desc 'Restore database from last backup file'
  task restore: ['db:create', :environment, :load_config] do
    database_adapter = DatabaseAdapters::Base.for(connection_config, current_database)
    database_adapter.kill_connections
    execute_task!('db:drop')
    execute_task!('db:create')
    database_adapter.restore
  end

  desc 'Kill PostgreSQL connections'
  task kill_postgres_connections: [:environment, :load_config] do
    database_adapter = DatabaseAdapters::Base.for(connection_config, current_database)
    database_adapter.kill_connections
  end

  desc 'Cleanup old Database dumps and keep only specified number of dumps'
  task cleanup: [:environment, :load_config] do
    database_adapter = DatabaseAdapters::Base.for(connection_config, current_database)
    database_adapter.cleanup_old_database_dumps
  end

  def connection_config
    ActiveRecord::Base.connection_config
  end

  def current_database
    ActiveRecord::Base.connection.current_database
  end

  def execute_task!(task_name)
    Rake::Task[task_name].reenable
    Rake::Task[task_name].invoke
  end
end
