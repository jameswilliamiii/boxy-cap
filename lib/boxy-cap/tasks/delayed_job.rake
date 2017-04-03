namespace :boxy do
  namespace :delayed_job do
    desc 'Restart the delayed_job process'
    task :restart do
      on roles(:app) do
        execute :sudo, :monit, "-g #{fetch(:monit_delayed_job_name)} restart"
      end
    end

    desc 'Stop the delayed_job process'
    task :stop do
      on roles(:app) do
        execute :sudo, :monit, "-g #{fetch(:monit_delayed_job_name)} stop"
      end
    end

    desc 'Start the delayed_job process'
    task :start do
      on roles(:app) do
        execute :sudo, :monit, "-g #{fetch(:monit_delayed_job_name)} start"
      end
    end
  end
end

namespace :load do
  task :defaults do
    set :monit_delayed_job_name, 'delayed_job'
  end
end
