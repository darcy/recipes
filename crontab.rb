namespace :crontab do
  task :update, :roles => :app, :except => {:crontab => false} do
    run "cd #{release_path}/script && [ -f crontab-#{rails_env} ] && crontab crontab-#{rails_env}" if File.exists?("script/crontab-#{rails_env}")
  end

  desc "Display the crontab"
  task :show, :roles => :app, :except => {:crontab => false}  do
    run "crontab -l"
  end

  task :setup_files do
    path = "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
    %w(production staging).each do |stage|
    example1 = "#*/5 * * * * #{current_path}/script/runner -e #{stage} CronJob.often >> #{shared_path}/log/jobs_often.log 2>&1"
    example2 = "#2 0 * * * #{current_path}/script/runner -e #{stage} CronJob.daily >> #{shared_path}/log/jobs_daily.log 2>&1"

      run_locally "echo #{path} > script/crontab-#{stage}"
      run_locally "echo '#{example1}' >> script/crontab-#{stage}"
      run_locally "echo '#{example2}' >> script/crontab-#{stage}"
      run_locally "echo '' >> script/crontab-#{stage}" #needs newline at the end of the file
    end
  end
end

after   "deploy:symlink_configs",   "crontab:update"

