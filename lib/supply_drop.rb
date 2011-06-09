require 'supply_drop/rsync'

Capistrano::Configuration.instance.load do
  namespace :puppet do
    set :puppet_source, '.'
    set :puppet_destination, '/tmp/supply_drop'
    set :puppet_command, 'puppet'
    set :puppet_lib, "#{puppet_destination}/modules"
    set :puppet_parameters, 'puppet.pp'

    desc "installs puppet"
    task :bootstrap, :except => { :nopuppet => true } do
      run "mkdir -p #{puppet_destination}"
      run "#{sudo} apt-get update"
      run "#{sudo} apt-get install -y puppet rsync"
    end

    desc "pushes the current puppet configuration to the server"
    task :update_code, :except => { :nopuppet => true } do
      find_servers_for_task(current_task).each do |server|
        rsync_cmd = Rsync.command(
          puppet_source,
          Rsync.remote_address(server.user || fetch(:user, ENV['USER']), server.host, puppet_destination),
          :delete => true,
          :excludes => ['.git'],
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
    puppet_cmd = "cd #{puppet_destination} && #{sudo} PUPPETLIB=#{puppet_lib} #{puppet_command} #{puppet_parameters}"
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
