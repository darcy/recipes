set :scm, :git
set :git_enable_submodules, 1


namespace :vcs do
  task :certify do
    run_locally source.local.scm("tag", "-f", branch, certify_branch)
    run_locally source.local.scm("push", "-f", fetch(:repository), "tag", branch)
  end

  task :get_revision do
    begin
      rev = nil
      run "cat #{current_path}/REVISION" do |ch, stream, data|
        if stream == :err
          logger.debug "capured output on STDERR: #{data}"
        else # stream == :out
          rev = data
        end
      end
      set :current_revision, rev
      puts "current revision is #{rev}"
    rescue
      "No revision found"
    end
  end
  
  task :tag_release do
    # if "production" == branch || (exists?(:tag_release_branch) and tag_release_branch == branch)
      # name =  "#{fetch(:web_domain)}-#{Time.new.strftime("%Y%d%m%H%M%S")}"
      prev = "#{fetch(:web_domain)}-prev"
      current = "#{fetch(:web_domain)}-current"
      run_locally source.local.scm("tag", "-f", %{"#{prev}"}, %{"#{current}"}) # real_revision executes a fetch
      run_locally source.local.scm("tag", "-f", %{"#{current}"}, fetch(:real_revision)) # real_revision executes a fetch
      run_locally source.local.scm("push", fetch(:repository), "--tags", '-f')
    # end
  end
  
end

# before  "deploy:update_code",     "vcs:certify"
before  "deploy:update_code",     "vcs:get_revision"
after   "deploy:long",            "vcs:tag_release"
after   "deploy",                 "vcs:tag_release"
