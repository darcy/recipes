namespace :apache do
  
  desc "Stop Apache"
  task :stop do
    sudo "/etc/init.d/apache2 stop"
  end

  desc "Start Apache"
  task :start do
    sudo "/etc/init.d/apache2 start"
  end

  desc "Restart Apache"
  task :restart do
    sudo "/etc/init.d/apache2 restart"
    restart
  end
  
  desc "Reload Apache"
  task :reload do
    sudo "/etc/init.d/apache2 reload"
  end

end