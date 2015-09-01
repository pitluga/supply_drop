require 'capistrano/supply_drop/rsync'
require 'capistrano/supply_drop/async_enumerable'
require 'capistrano/supply_drop/thread_pool'
require 'capistrano/supply_drop/util'
load File.expand_path('../tasks/supply_drop.rake', __FILE__)
