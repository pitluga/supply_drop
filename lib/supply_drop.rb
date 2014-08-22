require 'supply_drop/rsync'
require 'supply_drop/async_enumerable'
require 'supply_drop/thread_pool'
require 'supply_drop/util'
require 'supply_drop/tasks'

set :puppet_source, '.'
set :puppet_destination, '/var/tmp/supply_drop'
set :puppet_command, 'puppet apply'
set :puppet_lib, lambda { "#{fetch(:puppet_destination)}/modules" }
set :puppet_parameters, lambda { fetch(:puppet_verbose) ? '--debug --trace --color false puppet.pp' : '--color false puppet.pp' }
set :puppet_verbose, false
set :puppet_excludes, %w(.git .svn)
set :puppet_parallel_rsync, true
set :puppet_parallel_rsync_pool_size, 10
set :puppet_runner, nil
set :puppet_lock_file, '/tmp/puppet.lock'
