require 'rake'

Gem::Specification.new do |s|
  s.name = "supply_drop"
  s.summary = "Masterless puppet with capistrano"
  s.description = "See http://github.com/pitluga/supply_drop"
  s.version = "0.6.1"
  s.author = "Tony Pitluga"
  s.email = "tony.pitluga@gmail.com"
  s.homepage = "http://github.com/pitluga/supply_drop"
  s.files = FileList["README.md", "Rakefile", "lib/**/*.rb", "examples/**/*"]
end
