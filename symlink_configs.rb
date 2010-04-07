namespace :deploy do
  task :symlink_configs do
    run "mkdir -p #{latest_release}/config/initializers"
    run "mkdir -p #{shared_path}/config/initializers"
    run "mkdir -p #{shared_path}/public/files"

    run "ln -nfs #{shared_path}/config/database.yml #{latest_release}/config/database.yml"
    run "ln -nfs #{shared_path}/public/files #{latest_release}/public/files"
    run "find #{shared_path}/config/initializers -name *.rb | "\
        "xargs -i basename {} | "\
        "xargs -i ln -nfs #{shared_path}/config/initializers/{} #{latest_release}/config/initializers/{}"
  end
end
after   "deploy:symlink",           "deploy:symlink_configs"