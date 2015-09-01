lock '3.2.1'

# Cap3 uses non-interactive, non-login shell so we must build PATH manually
set :default_env, { 'PATH' => "/opt/vagrant_ruby/bin:$PATH" }
