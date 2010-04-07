namespace :deploy do
  
  task :stop_nginx do
    sudo "/etc/init.d/nginx stop"
  end
  
  task :start_nginx do
    sudo "/etc/init.d/nginx start"
  end
  
  task :restart_nginx do
    sudo "/etc/init.d/nginx restart"
    restart
  end

end