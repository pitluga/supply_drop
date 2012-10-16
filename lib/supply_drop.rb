require 'supply_drop/rsync'
require 'supply_drop/async_enumerable'
require 'supply_drop/plugin'
require 'supply_drop/syntax_checker'
require 'supply_drop/thread_pool'
require 'supply_drop/util'
require 'supply_drop/writer/batched'
require 'supply_drop/writer/file'
require 'supply_drop/writer/streaming'
require 'supply_drop/tasks'

Capistrano.plugin :supply_drop, SupplyDrop::Plugin
