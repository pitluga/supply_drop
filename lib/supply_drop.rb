require 'supply_drop/rsync'
require 'supply_drop/async_enumerable'
require 'supply_drop/util'

Capistrano::Configuration.instance.load do
  namespace :puppet do
    set :puppet_source, '.'
    set :puppet_destination, '/tmp/supply_drop'
    set :puppet_command, 'puppet'
    set :puppet_lib, "#{puppet_destination}/modules"
    set :puppet_parameters, lambda { puppet_verbose ? '--debug --trace puppet.pp' : 'puppet.pp' }
    set :puppet_verbose, false
    set :puppet_excludes, %w(.git .svn)
    set :puppet_stream_output, false
    set :puppet_parallel_rsync, true

    namespace :bootstrap do
      desc "installs puppet via rubygems on an osx host"
      task :osx do
        if fetch(:use_sudo, true)
          run "#{sudo} gem install puppet --no-ri --no-rdoc"
        else
          run "gem install puppet --no-ri --no-rdoc"
        end
      end

      desc "installs puppet via apt on an ubuntu host"
      task :ubuntu do
        run "mkdir -p #{puppet_destination}"
        run "#{sudo} apt-get update"
        run "#{sudo} apt-get install -y puppet rsync"
      end
    end

    desc "pushes the current puppet configuration to the server"
    task :update_code, :except => { :nopuppet => true } do
      servers = SupplyDrop::Util.optionally_async(find_servers_for_task(current_task), puppet_parallel_rsync)
      servers.each do |server|
        rsync_cmd = SupplyDrop::Rsync.command(
          puppet_source,
          Rsync.remote_address(server.user || fetch(:user, ENV['USER']), server.host, puppet_destination),
          :delete => true,
          :excludes => puppet_excludes,
          :ssh => { :keys => ssh_options[:keys], :config => ssh_options[:config] }
        )
        logger.debug rsync_cmd
        system rsync_cmd
      end
    end

    desc "runs puppet with --noop flag to show changes"
    task :noop, :except => { :nopuppet => true } do
      update_code
      puppet :noop
    end

    desc "applies the current puppet config to the server"
    task :apply, :except => { :nopuppet => true } do
      update_code
      puppet :apply
    end
  end

  def puppet(command = :noop)
    sudo_cmd = fetch(:use_sudo, true) ? sudo : ''
    puppet_cmd = "cd #{puppet_destination} && #{sudo_cmd} #{puppet_command} --modulepath=#{puppet_lib} #{puppet_parameters}"
    flag = command == :noop ? '--noop' : ''

    outputs = {}
    begin
      run "#{puppet_cmd} #{flag}" do |channel, stream, data|
        if puppet_stream_output
          print data
          $stdout.flush
        else
          outputs[channel[:host]] ||= ""
          outputs[channel[:host]] << data
        end
      end
      logger.debug "Puppet #{command} complete."
    ensure
      unless puppet_stream_output
        outputs.each_pair do |host, output|
          logger.info "Puppet output for #{host}"
          logger.debug output, "#{host}"
        end
      end
    end
  end
end
