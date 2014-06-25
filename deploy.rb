namespace :deploy do
  task :long do
    transaction do
      update_code
      # web.disable
      symlink
      migrate
    end

    restart
    # web.enable
  end

  task :symlink_configs do
    run "mkdir -p #{latest_release}/config/initializers"
    run "mkdir -p #{shared_path}/config/initializers"
    run "mkdir -p #{shared_path}/public/files"
    run "mkdir -p #{shared_path}/export"

    run "ln -nfs #{shared_path}/config/database.yml #{latest_release}/config/database.yml"
    run "ln -nfs #{shared_path}/public/files #{latest_release}/public/files"
    run "ln -nfs #{shared_path}/export #{latest_release}/export"
    run "find #{shared_path}/config/initializers -name *.rb | "\
        "xargs -i basename {} | "\
        "xargs -i ln -nfs #{shared_path}/config/initializers/{} #{latest_release}/config/initializers/{}"
  end

end

before "deploy:create_symlink", "deploy:symlink_configs"
after "deploy",         "deploy:cleanup"
after "deploy:long",    "deploy:cleanup"
