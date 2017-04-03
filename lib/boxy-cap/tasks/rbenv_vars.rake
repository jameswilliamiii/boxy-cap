namespace :boxy do
  namespace :config do

    task vars: 'vars:show'

    namespace :vars do

      before 'deploy:check:linked_files', 'config:vars:ensure_shared_file_exists'

      desc 'Show current .rbenv-vars file'
      task :show do
        on roles(:all) do |host|
          within shared_path do
            execute :cat, '.rbenv-vars'
          end
        end
      end

      desc 'Edit remote .rbenv-vars file'
      task :edit do
        on roles(:all), backend: :ssh_command do |*args|
          within shared_path do
            execute('\"\${EDITOR:-vi}\"', '.rbenv-vars')
          end
        end
      end

      desc 'Ensure .rbenv-vars file exists before linked_directories check'
      task :ensure_shared_file_exists do
        on release_roles :all do |host|
          unless test "[ -f #{shared_path.join('.rbenv-vars')} ]"
            execute :touch, shared_path.join('.rbenv-vars')
          end
        end
      end
    end
  end
end
