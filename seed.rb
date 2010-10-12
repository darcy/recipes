namespace :deploy do
  namespace :seed do
  
    set(:seed_files) {["files"]}
    set(:seed_path) {"#{shared_path}/seeds"}

    desc 'Seeds both files and database from local machine'
    task :default do
      files
      db
    end
  
    desc 'Iterates through "seed_files" which are presumed to be in "public", and uploads them to the server'
    task :files do
      run "mkdir -p #{seed_path}"
      run "mkdir -p #{shared_path}/public"
      seed_files.each do |f|
        system "cd public ; zip ../tmp/#{f}.zip -r #{f} ; cd .."
        put File.read("tmp/#{f}.zip"), "#{seed_path}/#{f}.zip"
        run "cd #{shared_path}/public/ ; unzip -o #{seed_path}/#{f}.zip ; rm -f #{seed_path}/#{f}.zip"
        system "rm -f tmp/#{f}.zip"
      end
    end

    desc 'Dumps local db and seeds the server with it.'
    task :db do
      run("cat #{shared_path}/config/database.yml") { |channel, stream, data| @environment_info = YAML.load(ERB.new(data).result)[rails_env] }

      dbhost = @environment_info['host'] || "localhost"
      dbuser = @environment_info['username']
      dbpass = @environment_info['password']
      dbname = @environment_info['database']

      yml = File.expand_path("config/database.yml")
      config = YAML.load_file(yml)
      cdatabase = config['development']['database']
      cusername = config['development']['username']
      cpassword = config['development']['password']

      pass = (cpassword.nil? or cpassword.empty?) ? "" : "-p#{cpassword}"
      system "mysqldump -u#{cusername} #{pass} #{cdatabase} > tmp/dump.sql"
      run "mkdir -p #{seed_path}"
      put File.read('tmp/dump.sql'), "#{seed_path}/dump.sql"
      system "rm -f tmp/dump.sql"
      
      run "mysql -u #{dbuser} -h #{dbhost} -p #{dbname} < #{seed_path}/dump.sql" do |ch, stream, out |
         ch.send_data "#{dbpass}\n" if out=~ /^Enter password:/
      end
    end
  
  end
end