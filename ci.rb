# run tests before deploying
# You can always skip tests: cap staging deploy -s skip_test=1

namespace :certify do
  
  task :default do
    top.ci.tests
    top.ci.features
    top.vcs.certify
  end
  
  task :tests do
    if !exists?(:skip_test)
      unless system("rake test")
        puts "", "\033[0;31m" +
        "   +++   TESTS FAILED, FIX THEM BEFORE DEPLOYING   +++   " +
        "\033[m", ""
        exit
      end
      puts "Tests passed"
    else
      puts "Skipping Tests"
    end
  end

  task :features do
    if !exists?(:skip_test)
      unless system("cucumber")
        puts "", "\033[0;31m" +
        "   +++   FEATURES FAILED, FIX THEM BEFORE DEPLOYING   +++   " +
        "\033[m", ""
        exit
      end
      puts "Features passed"
    else
      puts "Skipping Tests"
    end
  end

end

