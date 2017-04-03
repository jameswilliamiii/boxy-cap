namespace :boxy do
  namespace :logs do
    desc 'check last 5 deployed branches  and commits'
    task :revision do
      on roles(:app), in: :sequence, wait: 1 do
        execute "tail -n 5 #{deploy_to}/revisions.log"
      end
    end
    desc 'check all deployed branches and commits'
    task :revision_all do
      on roles(:app), in: :sequence, wait: 1 do
        execute "cat  #{deploy_to}/revisions.log"
      end
    end
  end
end
