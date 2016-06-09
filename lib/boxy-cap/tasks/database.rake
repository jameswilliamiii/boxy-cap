require 'securerandom'

namespace :deploy do
  namespace :check do
    task :linked_files => 'config/database.yml'
  end
end

namespace :db do
  desc 'Create Database'
  task :create do
    on primary fetch(:migration_role) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'db:create'
        end
      end
    end
  end

  desc 'Create backup of Database'
  task :backup do
    on primary fetch(:migration_role) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'db:backup'
          execute :rake, 'db:cleanup'
          no_of_days = fetch(:db_dump_retention).to_i
        end
      end
    end
  end

  desc 'Restore the latest dump of Database'
  task :restore do
    on primary fetch(:migration_role) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'db:restore'
        end
      end
    end
  end

  desc 'Read current server properties for database restore'
  task :read_server_address_for_db_restore do
    host = roles(:web).last
    puts "#{host.user}@#{host.hostname}"
  end

  desc 'Sync database from production'
  task :sync do
    on primary fetch(:migration_role) do
      raise "This task cannot be run in production" if fetch(:stage).to_s == 'production'

      from_env = ENV['FROM'] || 'production'
      system "cap #{from_env} db:backup"

      # Read user@hostname of production server to scp database dump
      from_server_address = `cap #{from_env} db:read_server_address_for_db_restore`.split("\n").last.chomp

      within release_path do
        with rails_env: fetch(:rails_env) do

          # Take a backup before restoring production database
          execute :rake, 'db:backup'
          execute :rake, 'db:cleanup'

          # Get database backup from production
          db_back_up_dir = fetch(:deploy_to) + "/shared/db/backups/"
          source_db_file =  db_back_up_dir + "#{fetch(:application)}_#{from_env}_latest.dump"
          destination_db_file = db_back_up_dir + "#{fetch(:application)}_#{fetch(:stage)}_latest.dump"
          execute :scp, "#{from_server_address}:#{source_db_file} #{destination_db_file}"

          # Execute database restore command
          execute :rake, 'db:restore'

          # Run de-identification task if required
          if ENV['DEIDENTIFY_TASK']
            execute :rake, ENV['DEIDENTIFY_TASK']
          end
        end
      end
    end
  end

  desc 'Download to local machine the latest backup'
  task :dump_download, :env_name do |task, args|
    on primary fetch(:migration_role) do
      within release_path do
        FileUtils.mkdir_p 'db/backups'
        env_name = args[:env_name] || fetch(:rails_env).to_s
        database_config_content = read_remote_database_config
        database_name = BoxyCap::Recipes::Util.database_name(env_name, database_config_content)
        backup_file = "db/backups/#{database_name}_latest.dump"
        download! "#{release_path}/#{backup_file}", backup_file
      end
    end
  end

  desc 'Upload to remote machine the latest backup'
  task :dump_upload, :env_name do |task, args|
    on primary fetch(:migration_role) do
      within release_path do
        FileUtils.mkdir_p 'db/backups'
        env_name = args[:env_name] || fetch(:rails_env).to_s
        database_config_content = read_remote_database_config
        database_name = BoxyCap::Recipes::Util.database_name(env_name, database_config_content)
        backup_file = "db/backups/#{database_name}_latest.dump"
        upload! backup_file, "#{release_path}/#{backup_file}"
      end
    end
  end

end


remote_file 'config/database.yml' => '/tmp/database.yml', roles: :app

after 'config/database.yml', :remove_db_tmp_file do
  File.delete '/tmp/database.yml'
end

file '/tmp/database.yml' do |t|
  default_template = <<-EOF
      base: &base
        adapter: sqlite3
        timeout: 5000
      development:
        database: #{shared_path}/db/development.sqlite3
        <<: *base
      test:
        database: #{shared_path}/db/test.sqlite3
        <<: *base
      production:
        database: #{shared_path}/db/production.sqlite3
        <<: *base
  EOF

  location = fetch(:template_dir,  File.join(File.dirname(__FILE__), 'templates', 'database.yml.erb'))
  template = File.file?(location) ? File.read(location) : default_template

  config = ERB.new(template)
  File.open t.name, 'w' do |f|
    f.puts config.result(binding)
  end
end

def read_remote_database_config(path = 'config/database.yml')
  capture :cat, path
end
