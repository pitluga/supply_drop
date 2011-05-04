puts 'loading'

task :echo, :roles => :foo do
  run 'echo hello'
end
