namespace :mirror do

  desc "Mirrors a remote server locally to the development environment (destructive)"
  task :default, :roles => :db, :only => { :primary => true } do
    set :mirror_env, "development"
    environment
    run_locally "test -e public/files && mv public/files tmp/files_#{Time.now.to_i}"
    run_locally "ln -nfs ../#{files}/files public/files"
  end
  

  desc "Mirrors a remote server locally to the development environment"
  task :environment do
    set :mirror_env, rails_env if !exists?(:mirror_env)
    
    local_config = YAML.load_file("config/database.yml")[mirror_env]
    if !local_config or !local_config['database']
      puts "You need to set up the #{mirror_env} in your database.yml on your local machine"
    end
    top.backup.download
    backup_name=top.backup.backup_name
    
    run_locally "unzip tmp/#{rails_env}-#{backup_name}.zip -d tmp/#{rails_env}-#{backup_name}"

    set :files, "tmp/#{rails_env}-#{backup_name}/files-#{backup_name}"
    run_locally "unzip #{files}.zip -d #{files}"
   
    #database
    run_locally "gunzip -f tmp/#{rails_env}-#{backup_name}/database-#{backup_name}.gz"
    
    mysql_options = "-u #{local_config['username']} --password='#{local_config['password']}' -h #{local_config['host'] || 'localhost'}"
    run_locally "mysqldump #{mysql_options} #{local_config['database']} > tmp/local-#{local_config['database']}-#{Time.now.to_i}.sql"
    run_locally "mysql #{mysql_options} -e \"drop database if exists #{local_config['database']}\""
    run_locally "mysqladmin #{mysql_options} create #{local_config['database']}"
    run_locally "mysql #{mysql_options} #{local_config['database']} < tmp/#{rails_env}-#{backup_name}/database-#{backup_name}"
  end

end