namespace :nginx do
  
  task :stop do
    sudo "/etc/init.d/nginx stop"
  end
  
  task :start do
    sudo "/etc/init.d/nginx start"
  end
  
  task :restart do
    sudo "/etc/init.d/nginx restart"
  end

end