namespace :boxy do
  namespace :deploy do

    desc 'Setup application on first run'
    task :setup do
      invoke 'deploy:check'
      invoke 'deploy:updating'
      invoke 'bundler:install'
      invoke 'boxy:db:create'
    end
  end
end
