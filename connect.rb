namespace :connect do
  set :bash, "bash --rcfile /home/deploy/.bash_profile"
  set :port, 22 unless exists? :port
  
  desc "drop you in ssh on remote" 
  task :default do
    exec "ssh -t #{user}@#{domain} -p #{port} \"cd #{deploy_to}; #{bash}\""
  end
  
  desc "remotely console" 
  task :console, :roles => :app do
    exec "ssh -t #{user}@#{domain} -p #{port} \"cd #{current_path}; RAILS_ENV=#{rails_env} script/console; #{bash}\""
  end

  desc "tail rails log files" 
  task :tail, :roles => :app do
    run "tail -f #{shared_path}/log/#{rails_env}.log" do |channel, stream, data|
      puts  # for an extra line break before the host name
      puts "#{channel[:host]}: #{data}" 
      break if stream == :err    
    end
  end

  desc "remotely dbconsole (experimental)" 
  task :dbconsole, :roles => :app do
    exec "ssh -t #{user}@#{domain} -p #{port} \"cd #{current_path}; RAILS_ENV=#{rails_env} script/dbconsole; #{bash}\""
  end
  
end