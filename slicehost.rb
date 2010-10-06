#############################################################
# Slicehost Setup
#############################################################
#
# Start out with:
# => cap slicehost:setup_user
# => cap slicehost:setup_server
#
# Mysql is still messy, generally do this when it chokes on the blue screen:
# => cap connect
# => sudo apt-get install mysql-server libmysql-ruby -y
# => cap slicehost:finalize_setup
#
# Deploy
# => cap deploy:long
#
# Finally
# => restart the Slicehost slice on manage.slicehost.com
#
#
#
# NOTES:
# Crontab issues
# 3. not logging
#   sudo vi /etc/syslog.conf
#   enable the line that has cron
#   sudo /etc/init.d/sysklogd restart
# 4. environment not setup
#   crontab -e
#   add at the top: 
#


namespace :slicehost do

  task :config do
    set :nginx_dir, "/etc/nginx"
    set :user,                "deploy"
    set :deploy_to, "/home/deploy/#{application}"
    set :shared_path, "#{deploy_to}/shared" #bug where this wasn't getting set correctly
    default_run_options[:pty] = true
    set :use_sudo, true
    set :scm_verbose, true
    set :deploy_via, :remote_cache
  end
  
  desc "Setup Environment"
  task :setup_server do
    deploy_user = user
    
    update_apt_get
    install_dev_tools
    install_git
    install_rails_stack
    install_apache
    install_passenger
    config_passenger_apache
    config_apache_mods
    # config_passenger_nginx
    # config_nginx
    top.apache.reload
    install_imagemagick
    setup_crontab
    setup    
    sudo "chown -R #{user}:#{user} /home/#{user}"
    
    install_mysql #this is still funky - just run 'sudo apt-get install mysql-server libmysql-ruby -y'
    setup_server_finish
  end

  task :setup_server_finish do
    install_mysql_bindings
  end

  task :setup_crontab do
    deploy_user = user
    run "echo 'EDITOR=\"/usr/bin/vim\"' >> ~/.bash_profile"
    run "echo 'export EDITOR' >> ~/.bash_profile"
    sudo "usermod -a -G crontab #{deploy_user}"
    sudo "chgrp crontab /var/spool/cron/crontabs"
    sudo "chmod 730 /var/spool/cron/crontabs"
    sudo "sed -i 's/#cron/cron/g' /etc/syslog.conf"
    sudo "/etc/init.d/sysklogd restart"
  end
  
  desc "Use this after you clone a prod server to a staging server, run as cap staging slicehost:setup_staging"
  task :setup_staging do
    if rails_env != "staging"
      puts "this is to be run in with the staging environment"
      puts "=> cap staging slicehost:setup_staging"
      exit
    end
    run "mysqladmin -uroot drop -f #{application}_staging"
    run "mysqladmin -uroot create #{application}_staging"
    run "mysqldump -uroot #{application}_production > production-dump.sql"
    run "mysqladmin -uroot drop -f #{application}_production" #we have a backup now, safe
    run "mysql -uroot #{application}_staging < production-dump.sql"
    config_apache_vhost
    top.apache.reload
    top.deploy.restart
  end
  
  task :setup do
    top.deploy.setup
    sudo "chown -R #{user}:#{user} #{deploy_to}" #needed when adding an app to existing server
    setup_config
    create_databases
    config_apache_vhost
    top.apache.reload
    top.crontab.setup_files
  end
  
  task :setup_user do
    deploy_user = user
    set :user , "root"
    sudo "/usr/sbin/useradd --create-home --shell=/bin/bash deploy"
    password_set = false
    while !password_set do
      password = Capistrano::CLI.ui.ask "#{deploy_user} UNIX password:"
      password_confirmation = Capistrano::CLI.ui.ask "#{deploy_user} Retype UNIX password:"
      if password != ''
        if password == password_confirmation
          # run "echo \"#{ password }\" | sudo passwd --stdin #{deploy_user}"
          sudo "echo \"#{deploy_user}:#{password}\">pass.txt; cat pass.txt | chpasswd ; rm pass.txt"
          password_set = true
        else
          puts "Passwords did not match"
        end
      else
        puts "Password cannot be blank"
      end
    end
    sudo "echo '#{deploy_user}    ALL=(ALL) ALL' >> /etc/sudoers"
    sudo "echo \"alias 'l=ls -l'\" >> /home/#{deploy_user}/.bash_profile"
    sudo "echo \"alias 'la=ls -la'\" >> /home/#{deploy_user}/.bash_profile"
    sudo "mkdir -p /home/#{deploy_user}/.ssh"
    sudo "chmod 700 /home/#{deploy_user}/.ssh"
    # run "touch .ssh/authorized_keys"
    sudo "echo \"ssh-dss AAAAB3NzaC1kc3MAAACBAIpXW8t1wJO40g4swruYOZm+16Yf5QrPUozaGgt1psrJ8SFRWb49jThX5x9ZVSRi1EKdPy6Z1Hh3gBdNNW0KlMYO0ao9ZtycnS4W2MEVhH9teCtkIVzfG2xWopHyYyWtdiinGVPyu7scxw1EJGXNo5PZ59jzdsRXJtAFZgFAC9RpAAAAFQDJa/0OjzXCvZ3gorE5h4/MoYb+rwAAAIBjDc+a8zltj7tIzweqlNNtdbBHb7nwHLkbvJl0zpLw5VCk1ohp/wSOK3MRkIMOgshLm+lEWRLe5htQh/64XFZdTr2QU0YFyIE/UaefJz0W6jdwqGGny0BdBO6QAH/OBHTk0tJF8QffB2Yj6JnZaF8abyv7/s4HtHC1JwLSp6S+nQAAAIBwqrOJPTPqP3oeriPEbKnTgFwKnBRKpz208Ya2JiCK31SL0/vU7ML7H1ays5unRPpYS46PY4yZDx91+wmqY6Rn/bCHHNk6OooJu+gsS0QoDAOFtCiyfTfFiKOU1+iBEP1aeOwCF39YNHojU/EgEVcKyoJ2YFDIVgG19MCBwHbj3Q== darcy@Technicraft.local\" >> /home/#{deploy_user}/.ssh/authorized_keys"
    sudo "chmod 600 /home/#{deploy_user}/.ssh/authorized_keys"
    sudo "chown -R #{deploy_user}:#{deploy_user} /home/#{deploy_user}"
  end
  
  task :setup_config do
    db_config = ERB.new <<-EOF
production:
  adapter: mysql
  encoding: utf8
  database: #{application}_production
  username: root
  password: 
  socket: /var/run/mysqld/mysqld.sock

staging:
  adapter: mysql
  encoding: utf8
  database: #{application}_staging
  username: root
  password: 
  socket: /var/run/mysqld/mysqld.sock
      EOF
      run "mkdir -p #{shared_path}/config" 
      run "mkdir -p #{shared_path}/public/files" 
      put db_config.result, "#{shared_path}/config/database.yml"
  end

  task :create_databases do
    run "mysqladmin -uroot create #{application}_production"
    run "mysqladmin -uroot create #{application}_staging"
  end

  desc "Update apt-get sources"
  task :update_apt_get do
    sudo "apt-get update"
  end
  
  desc "Install Development Tools"
  task :install_dev_tools do
    sudo "apt-get install build-essential -y"
    sudo "apt-get install zip -y"
    sudo "apt-get install unzip -y"
    sudo "apt-get install rsync -y"
  end
  
  desc "Install Git"
  task :install_git do
    sudo "apt-get install git-core git-svn -y"
    run "mkdir ~/bin"
    run "cd bin; git clone http://github.com/darcy/git-ftp.git git-ftp.git; ln -s git-ftp.git/git-ftp.sh git-ftp"
    run "echo 'export PATH=$PATH:~/bin' >> ~/.bash_profile"
  end
  
  desc "Install Subversion"
  task :install_subversion do
    sudo "apt-get install subversion -y"
  end
  
  desc "Install MySQL"
  task :install_mysql do
    # sudo "echo 'mysql-server mysql-server/root_password select' | sudo debconf-set-selections"
    # sudo "dpkg --configure -a"
    sudo "apt-get install mysql-server libmysql-ruby -y"
  end
  
  desc "Install PostgreSQL"
  task :install_postgres do
    sudo "apt-get install postgresql libpgsql-ruby -y"
  end
  
  desc "Install SQLite3"
  task :install_sqlite3 do
    sudo "apt-get install sqlite3 libsqlite3-ruby -y"
  end
  
  desc "Install Ruby, Gems, and Rails"
  task :install_rails_stack do
    [ "sudo apt-get install ruby ruby1.8-dev irb ri rdoc libopenssl-ruby1.8 -y",
      "sudo apt-get install libxslt1-dev libxml2-dev -y",
      "mkdir -p src",
      "cd src",
      "wget http://rubyforge.org/frs/download.php/45905/rubygems-1.3.1.tgz",
      "tar xzvf rubygems-1.3.1.tgz",
      "cd rubygems-1.3.1/ && sudo ruby setup.rb",
      "sudo ln -s /usr/bin/gem1.8 /usr/bin/gem",
      "sudo gem update --system",
      "sudo gem install rails --no-ri --no-rdoc",
      "sudo gem install grit --no-ri --no-rdoc",
      "sudo gem install nokogiri --no-ri --no-rdoc"
    ].each {|cmd| run cmd}
  end
  
  desc "Install MySQL Rails Bindings"
  task :install_mysql_bindings do
    sudo "aptitude install libmysql-ruby1.8 -y"
  end
  
  desc "Install ImageMagick"
  task :install_imagemagick do
    sudo "apt-get install libxml2-dev libmagick9-dev imagemagick -y"
    sudo "gem install rmagick -v 2.12.2"
  end
  
  desc "Install Apache"
  task :install_apache do
    sudo "apt-get install apache2 apache2.2-common apache2-mpm-prefork
          apache2-utils libexpat1 apache2-prefork-dev libapr1-dev -y"
    sudo "chown :sudo /var/www"
    sudo "chmod g+w /var/www"
  end
  
  # desc "Install Nginx"
  # task :install_nginx do
  #   sudo "aptitude install nginx"
  # end
  
  desc "Install Passenger"
  task :install_passenger do
    run "sudo gem install passenger -v 2.2.3 --no-ri --no-rdoc"
  end
  
  desc "Configure Passenger"
  task :config_passenger_apache do
    input = ''
    run "sudo passenger-install-apache2-module --auto" do |ch,stream,out|
      next if out.chomp == input.chomp || out.chomp == ''
      print out
      if out =~ /(Enter|ENTER)/
        ch.send_data("\n") 
        # ch.send_data(input = $stdin.gets) 
      end
    end
    passenger_config =<<-EOF
LoadModule passenger_module /usr/lib/ruby/gems/1.8/gems/passenger-2.2.3/ext/apache2/mod_passenger.so
PassengerRoot /usr/lib/ruby/gems/1.8/gems/passenger-2.2.3
PassengerRuby /usr/bin/ruby1.8    
    EOF
    put passenger_config, "src/passenger"
    sudo "mv src/passenger /etc/apache2/conf.d/passenger"
  end
  
  # desc "Configure Passenger for Nginx"
  # task :config_passenger_nginx do
  #   sudo "apt-get install zlib1g-dev"
  #   input = ''
  #   run "sudo passenger-install-nginx-module --auto --auto-download --extra-configure-flags=\"--sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --pid-path=/var/run/nginx.pid --lock-path=/var/lock/nginx.lock --http-log-path=/var/log/nginx/access.log --http-client-body-temp-path=/var/tmp/nginx/body --http-proxy-temp-path=/var/tmp/nginx/proxy --http-fastcgi-temp-path=/var/tmp/nginx/fastcgi --with-http_ssl_module\"" do |ch,stream,out|
  #     next if out.chomp == input.chomp || out.chomp == ''
  #     print out
  #     if out =~ /(Press Enter to continue|Press ENTER to continue)/
  #       ch.send_data("\n") 
  #     elsif out =~ /(Enter your choice)/
  #       ch.send_data("1\n") 
  #     elsif out =~ /(Please specify a prefix directory)/
  #       ch.send_data("#{nginx_dir}\n")
  #       # ch.send_data(input = $stdin.gets) 
  #     end
  #   end
  # end
  
  # task :config_nginx do
  #   vhost_config =<<-EOF
  #   server {
  #       listen 80;
  #       server_name #{web_domain};
  #       root #{deploy_to}/current/public;
  #       passenger_enabled on;
  #       # if ($host != '#{web_domain}') {
  #       #    rewrite ^(.*)$ http://#{web_domain}$1 permanent;
  #       # }
  #   }
  #   EOF
  #   put vhost_config, "src/nginx_config"
  #   sudo "mkdir -p #{nginx_dir}/conf/servers"
  #   sudo "mv src/nginx_config #{nginx_dir}/conf/servers/#{application}.conf"
  #   sudo "mv #{nginx_dir}/conf/nginx.conf #{nginx_dir}/conf/nginx.conf.bak"
  #   sudo "sed 'N;$!P;$!D;$d' #{nginx_dir}/conf/nginx.conf.bak > ~/nginx.conf"
  #   sudo "mv ~/nginx.conf #{nginx_dir}/conf/nginx.conf"
  #   sudo "echo 'include #{nginx_dir}/conf/servers/*.conf' >> #{nginx_dir}/conf/nginx.conf"
  #   sudo "echo '} ' >> #{nginx_dir}/conf/nginx.conf"
  # 
  #   nginx_initd=<<-EOF
  #   #! /bin/sh
  #   
  #   ### BEGIN INIT INFO
  #   # Provides:          nginx
  #   # Required-Start:    $all
  #   # Required-Stop:     $all
  #   # Default-Start:     2 3 4 5
  #   # Default-Stop:      0 1 6
  #   # Short-Description: starts the nginx web server
  #   # Description:       starts nginx using start-stop-daemon
  #   ### END INIT INFO
  #   
  #   
  #   PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
  #   DIR=#{nginx_dir}
  #   DAEMON=$DIR/sbin/nginx
  #   NAME=nginx
  #   DESC=nginx
  #   
  #   test -x $DAEMON || exit 0
  #   
  #   # Include nginx defaults if available
  #   if [ -f /etc/default/nginx ] ; then
  #           . /etc/default/nginx
  #   fi
  #   
  #   set -e
  #   
  #   case "$1" in
  #     start)
  #           echo -n "Starting $DESC: "
  #           start-stop-daemon --start --quiet --pidfile $DIR/logs/$NAME.pid \
  #                   --exec $DAEMON -- $DAEMON_OPTS
  #           echo "$NAME."
  #           ;;
  #     stop)
  #           echo -n "Stopping $DESC: "
  #           start-stop-daemon --stop --quiet --pidfile $DIR/logs/$NAME.pid \
  #                   --exec $DAEMON
  #           echo "$NAME."
  #           ;;
  #     restart|force-reload)
  #           echo -n "Restarting $DESC: "
  #           start-stop-daemon --stop --quiet --pidfile \
  #                   $DIR/logs/$NAME.pid --exec $DAEMON
  #           sleep 1
  #           start-stop-daemon --start --quiet --pidfile \
  #                   $DIR/logs/$NAME.pid --exec $DAEMON -- $DAEMON_OPTS
  #           echo "$NAME."
  #           ;;
  #     reload)
  #         echo -n "Reloading $DESC configuration: "
  #         start-stop-daemon --stop --signal HUP --quiet --pidfile $DIR/logs/$NAME.pid \
  #             --exec $DAEMON
  #         echo "$NAME."
  #         ;;
  #     *)
  #           N=/etc/init.d/$NAME
  #           echo "Usage: $N {start|stop|restart|force-reload}" >&2
  #           exit 1
  #           ;;
  #   esac
  #   
  #   exit 0
  #   EOF
  #   put nginx_initd, "src/nginx_initd"
  #   sudo "mv src/nginx_initd /etc/init.d/nginx"
  #   sudo "chmod +x /etc/init.d/nginx"
  #   sudo "/usr/sbin/update-rc.d -f nginx defaults"
  #   top.deploy.start_nginx
  # end

  desc "Configure VHost"
  task :config_apache_vhost do
    vhost_config =<<-EOF
    NameVirtualHost *:80
    <VirtualHost *:80>
      ServerName #{web_domain}
      ServerAlias #{web_alias}
      DocumentRoot #{deploy_to}/current/public
      RailsEnv #{rails_env}
    </VirtualHost>
    EOF
    if exists?(:ssl_file)
      # SSLCertificateChainFile ssl/gd_bundle.crt
      chain_file = exists?(:ssl_chain_file) ? "SSLCertificateChainFile ssl/#{ssl_chain_file}.crt" : ""
      vhost_config +=<<-EOF    
      NameVirtualHost *:443
      <VirtualHost *:443>
        ServerName #{web_domain}
        ServerAlias #{web_alias}
        DocumentRoot #{deploy_to}/current/public
        RailsEnv #{rails_env}
        SSLEngine on
        SSLCertificateFile ssl/#{ssl_file}.crt
        SSLCertificateKeyFile ssl/#{ssl_file}.key
        #{chain_file}
        SSLProtocol all -SSLv2 
      </VirtualHost>
      EOF
    end
    put vhost_config, "src/vhost_config"
    sudo "mv src/vhost_config /etc/apache2/sites-available/#{application}"
    sudo "a2ensite #{application}"
  end
  
  task :config_apache_mods do
    sudo "a2enmod ssl"
    sudo "a2enmod rewrite"
    sudo "sudo a2dissite default"
  end
  # 
end

before("deploy:cleanup") { set :use_sudo, false }
