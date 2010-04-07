namespace :connect do
  task :default do
    exec "ssh #{user}@#{domain}"
  end
end