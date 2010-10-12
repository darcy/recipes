set :files_dirname, "files"
set :files_location, "public/"
namespace :backup do

  desc "Backup both files and the database on the server, and bundles it into a zip"
  task :default do
    db
    files
    run "cd #{backup_path}; zip -r #{backup_name}.zip *#{backup_name}*"
  end

  desc "Makes a backup, then downloads it to your tmp directory"
  task :download do
    default
    `mkdir -p tmp`
    get "#{backup_path}/#{backup_name}.zip", "tmp/#{rails_env}-#{backup_name}.zip"
  end
  
  desc "Backup the files to a zip file on the server"
  task :files do
    set :file_backup_name, "#{files_dirname}-#{backup_name}"
    run "mkdir -p #{backup_path}"
    
    set :file_zip, "#{backup_path}/#{file_backup_name}.zip"
    run "cd #{shared_path}/#{files_location}; zip -r #{file_zip} #{files_dirname}"
  end
  
  desc "Backup the database to a zip file on the server"
  task :db, :roles => :db, :only => { :primary => true } do
    set :db_backup_name, "database-#{backup_name}"
    run "mkdir -p #{backup_path}"
    
    run("cat #{shared_path}/config/database.yml") { |channel, stream, data| @environment_info = YAML.load(ERB.new(data).result)[rails_env] }
  
    dbhost = @environment_info['host'] || "localhost"
    dbuser = @environment_info['username']
    dbpass = @environment_info['password']
    dbname = @environment_info['database']
  
    set :backup_tables, "" unless self[:backup_tables]
    # dbhost.sub!('-master', '-replica') if dbhost != 'localhost' # added for Solo offering, which uses localhost
    run "mysqldump --add-drop-table -u #{dbuser} -h #{dbhost} -p #{dbname} #{backup_tables} | gzip > #{backup_path}/#{db_backup_name}.gz" do |ch, stream, out |
       ch.send_data "#{dbpass}\n" if out=~ /^Enter password:/
    end
  end
  
  task :backup_name do
    set :backup_path, "#{shared_path}/backups"
    set :backup_file, "backup-#{release_name}" if !exists?(:backup_file)
    backup_file
  end
end

before "deploy:migrate", "backup:db"

