namespace :deploy do
  
  task :stop_apache do
    sudo "/etc/init.d/apache2 stop"
  end

  task :start_apache do
    sudo "/etc/init.d/apache2 start"
  end

  task :restart_apache do
    sudo "/etc/init.d/apache2 restart"
    restart
  end

end