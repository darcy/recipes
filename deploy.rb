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

    run "([ -f #{shared_path}/config/database.yml ] && ln -nfs #{shared_path}/config/database.yml #{latest_release}/config/database.yml) || true"
    %w(
      public/files
      export
    ).each do |d|
      run "([ -d #{shared_path}/#{d} ] && ln -nfs #{shared_path}/#{d} #{latest_release}/#{d}) || true"
    end

    run "find #{shared_path}/config/initializers -name *.rb | "\
        "xargs -i basename {} | "\
        "xargs -i ln -nfs #{shared_path}/config/initializers/{} #{latest_release}/config/initializers/{}"
  end

end

before "deploy:create_symlink", "deploy:symlink_configs"
after "deploy",         "deploy:cleanup"
after "deploy:long",    "deploy:cleanup"
