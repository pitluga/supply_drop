require 'rake'

Gem::Specification.new do |s|
  s.name = "supply_drop"
  s.summary = "Serverless puppet with capistrano"
  s.description = "See http://github.com/pitluga/supply_drop"
  s.version = "0.1.0"
  s.author = "Tony Pitluga"
  s.email = "tony.pitluga@gmail.com"
  s.homepage = "http://github.com/pitluga/supply_drop"
  s.files = FileList["README", "Rakefile", "{lib,examples}/**/*.rb"]
end
