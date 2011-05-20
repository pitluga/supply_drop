Capistrano::Configuration.instance.load do
  namespace :puppet do
    set :puppet_target, '/home/vagrant/supply_drop'
    set :puppet_command, 'puppet'
    set(:puppet_lib) { "#{puppet_target}/modules" }
    set :puppet_parameters, 'puppet.pp'

    task :bootstrap, :except => { :nopuppet => true } do
      run "#{sudo} apt-get update"
      run "#{sudo} apt-get install -y puppet"
    end

    task :update_code, :except => { :nopuppet => true } do
      run "rm -rf #{puppet_target}"
      upload '.', puppet_target, :via => :scp, :recursive => true
    end

    task :noop, :except => { :nopuppet => true } do
      update_code
      puppet :noop
    end

    task :apply, :except => { :nopuppet => true } do
      update_code
      puppet :apply
    end
  end

  def puppet(command = :noop)
    puppet_cmd = "cd #{puppet_target} && #{sudo} PUPPETLIB=#{puppet_lib} puppet puppet.pp"
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
