desc "clean"
task :clean do
  rm_f Dir.glob("*.gem")
end

namespace :gem do
  desc "build the gem"
  task :build => :clean do
    sh "gem build supply_drop.gemspec"
  end

  desc "push the gem"
  task :push => :build do
    sh "gem push #{Dir.glob("*.gem").first}"
  end
end
