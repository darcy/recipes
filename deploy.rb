namespace :deploy do
  task :long do
    transaction do
      update_code
      web.disable
      symlink
      migrate
    end

    restart
    web.enable
  end
end

after "deploy", "deploy:cleanup"
after "deploy:long", "deploy:cleanup"