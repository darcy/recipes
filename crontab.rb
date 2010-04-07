namespace :crontab do
  task :update, :roles => :app, :only => {:crontab => true} do
    run "cd #{release_path}/script && [ -f crontab-#{rails_env} ] && crontab crontab-#{rails_env}"
  end

  desc "Display the crontab"
  task :show, :roles => :app, :only => {:crontab => true}  do
    run "crontab -l"
  end
end

after   "deploy:symlink_configs",   "crontab:update"

