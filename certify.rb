# run tests before deploying

namespace :certify do
  
  task :default do
    top.certify.tests
    top.certify.specs
    top.certify.features
    top.vcs.certify
  end

  task :force do
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

  task :specs do
    if !exists?(:skip_specs)
      unless system("rake spec")
        puts "", "\033[0;31m" +
        "   +++   SPECS FAILED, FIX THEM BEFORE DEPLOYING   +++   " +
        "\033[m", ""
        exit
      end
      puts "Specs passed"
    else
      puts "Skipping Specs"
    end
  end

  task :features do
    if !exists?(:skip_features)
      unless system("cucumber")
        puts "", "\033[0;31m" +
        "   +++   FEATURES FAILED, FIX THEM BEFORE DEPLOYING   +++   " +
        "\033[m", ""
        exit
      end
      puts "Features passed"
    else
      puts "Skipping Features"
    end
  end

end

