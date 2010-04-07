namespace :deploy do
  
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end
  
  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
  
  # task :long do
  #   transaction do
  #     update_code
  #     web.disable
  #     symlink
  #     migrate
  #   end
  # 
  #   restart
  #   web.enable
  #   cleanup
  # end
  
end

namespace :passenger do
  desc "Kickstart app"
  task :kickstart do
    run "curl -I http://#{web_domain}/"
  end
end

after   "deploy:restart",  "passenger:kickstart"
