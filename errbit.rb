
namespace :errbit do
  
  task :deploy_hook do

    require 'airbrake'
    require 'cgi'
    require './config/initializers/errbit.rb'

    url = "https://#{Airbrake.configuration.host}/deploys.txt?api_key=#{Airbrake.configuration.api_key}"
    prev = "#{fetch(:web_domain)}-prev"
    current = "#{fetch(:web_domain)}-current"
    message = run_locally(source.local.scm("log", "#{prev}..#{current}", "--pretty=format:\"%s\"")).strip

    data = {
      :rails_env => fetch(:rails_env),
      :local_username => run_locally(source.local.scm("config", "--get", "github.user")).strip,
      :scm_repository => fetch(:repository),
      :scm_revision => run_locally(source.local.scm("rev-parse", "--short", "HEAD")).strip,
      :message => message
    }.collect{|k,v| "deploy[#{k.to_s}]=#{CGI.escape(v)}" }.join("&")
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
