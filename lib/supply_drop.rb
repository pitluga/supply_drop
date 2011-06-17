require 'supply_drop/rsync'

Capistrano::Configuration.instance.load do
  namespace :puppet do
    set :puppet_source, '.'
    set :puppet_destination, '/tmp/supply_drop'
    set :puppet_command, 'puppet'
    set :puppet_lib, "#{puppet_destination}/modules"
    set :puppet_parameters, lambda { puppet_verbose ? '--debug --trace puppet.pp' : 'puppet.pp' }
    set :puppet_verbose, false
    set :puppet_excludes, %w(.git .svn)

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
      find_servers_for_task(current_task).each do |server|
        rsync_cmd = Rsync.command(
          puppet_source,
          Rsync.remote_address(server.user || fetch(:user, ENV['USER']), server.host, puppet_destination),
          :delete => true,
          :excludes => puppet_excludes,
          :ssh => { :keys => ssh_options[:keys] }
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
        outputs[channel[:host]] ||= ""
        outputs[channel[:host]] << data
      end
      logger.debug "Puppet #{command} complete."
    ensure
      outputs.each_pair do |host, output|
        logger.info "Puppet output for #{host}"
        logger.debug output, "#{host}"
      end
    end
  end
end
