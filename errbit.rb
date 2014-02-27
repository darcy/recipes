
namespace :errbit do
  
  task :deploy_hook do

    require 'airbrake'
    require './config/initializers/errbit.rb'

    url = "https://#{Airbrake.configuration.host}/deploys.txt?api_key=#{Airbrake.configuration.api_key}"
    data = {
      :app => fetch(:application),
      :url => "http://"+fetch(:web_domain),
      :user => run_locally(source.local.scm("config", "--get", "github.user")).strip,
      :head => run_locally(source.local.scm("rev-parse", "--short", "HEAD")).strip,
      :head_long => run_locally(source.local.scm("rev-parse", "HEAD")).strip
      # git_log: 
    }.collect{|k,v| "#{k.to_s}=#{v}" }.join("&")
    run_locally "curl -silent --data \"#{data}\" #{url}"

    # application/x-www-form-urlencoded
    # app: the app name
    # user: email of the user deploying the app
    # url: the app URL (http://myapp.heroku.com or http://mydomain.com if you have custom domains enabled)
    # head: short identifier of the latest commit (first seven bytes of the SHA1 git object name)
    # head_long: full identifier of the latest commit
    # git_log: log of commits between this deploy and the last
  end

end
