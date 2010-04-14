namespace :connect do
  desc "drop you in ssh on remote" 
  task :default do
    exec "ssh #{user}@#{domain}"
  end
  
  desc "remotely console" 
  task :console, :roles => :app do
    input = ''
    run "cd #{current_path} && ./script/console #{rails_env}" do |channel, stream, data|
      next if data.chomp == input.chomp || data.chomp == ''
      print data
      channel.send_data(input = $stdin.gets) if data =~ /^(>|\?)>/
    end
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
    input = ''
    run "cd #{current_path} && ./script/dbconsole #{rails_env}" do |channel, stream, data|
      next if data.chomp == input.chomp || data.chomp == ''
      print data
      channel.send_data(input = $stdin.gets) if data =~ /^(mysql|    -)>/
    end
  end
  
end