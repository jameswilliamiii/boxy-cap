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
          execute :rake, 'db:cleanup', "ROTATE=#{fetch(:keep_releases)}"
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
