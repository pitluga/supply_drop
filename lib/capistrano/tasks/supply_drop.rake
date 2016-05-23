namespace :load do

  task :defaults do
    set :puppet_source, '.'
    set :puppet_destination, '/var/tmp/supply_drop'
    set :puppet_command, 'puppet apply'
    set :puppet_lib, lambda { "#{fetch(:puppet_destination)}/modules" }
    set :puppet_parameters, lambda { fetch(:puppet_verbose) ? '--debug --trace --color false puppet.pp' : '--color false puppet.pp' }
    set :puppet_verbose, false
    set :puppet_excludes, %w(.git .svn)
    set :puppet_includes, %w()
    set :puppet_parallel_rsync, true
    set :puppet_parallel_rsync_pool_size, 10
    set :puppet_runner, nil
    set :puppet_lock_file, '/tmp/puppet.lock'
  end
end

namespace :puppet do

  namespace :bootstrap do
    desc "installs puppet via rubygems on an osx host"
    task :osx do
      on roles(:puppet) do
        if fetch(:use_sudo, true)
          sudo :gem, "install puppet --no-ri --no-rdoc"
        else
          execute :gem, "install puppet --no-ri --no-rdoc"
        end
      end
    end

    desc "installs puppet via apt on an ubuntu or debian host"
    task :ubuntu do
      on roles(:puppet) do
        execute :mkdir, "-p #{fetch(:puppet_destination)}"
        sudo "apt-get update"
        sudo "apt-get install -y puppet rsync"
      end
    end

    desc "installs puppet via yum on a centos/red hat host"
    task :redhat do
      on roles(:puppet) do
        execute :mkdir, "-p #{fetch(:puppet_destination)}"
        sudo :yum, "-y install puppet rsync"
      end
    end

    namespace :puppetlabs do
      desc "setup the puppetlabs repo, then install via the normal method"
      task :ubuntu do
        on roles(:puppet) do
          execute :echo, :deb, "http://apt.puppetlabs.com/ $(lsb_release -sc) main | #{sudo} tee /etc/apt/sources.list.d/puppet.list"
          execute :echo, :deb, "http://apt.puppetlabs.com/ $(lsb_release -sc) dependencies | #{sudo} tee -a /etc/apt/sources.list.d/puppet.list"
          sudo "apt-key adv --keyserver keyserver.ubuntu.com --recv 4BD6EC30"
          puppet.bootstrap.ubuntu
        end
      end

      desc "setup the puppetlabs repo, then install via the normal method"
      task :redhat do
        info "PuppetLabs::RedHat bootstrap is not implemented yet"
      end
    end
  end

  desc "runs puppet with --noop flag to show changes"
  task :noop do
    begin
      on roles(:puppet) do
        lock
        prepare
      end
      run_locally do
        update_code
      end
      on roles(:puppet) do
        puppet(:noop)
      end
    ensure
      on roles(:puppet) do
        unlock
      end
    end
  end

  desc "an atomic way to noop and apply changes while maintaining a lock"
  task :noop_apply do
    begin
      on roles(:puppet) do
        lock
        prepare
      end
      run_locally do
        update_code
      end

      on roles(:puppet) do
        puppet(:noop)
      end

      q = "Apply changes?".to_sym
      ask(q, "y/N")

      if (fetch(q).strip.downcase == "y")
        puts "Applying changes"
        on roles(:puppet) do
          puppet(:apply)
        end
      end
    ensure
      on roles(:puppet) do
        unlock
      end
    end
  end

  desc "alias for noop_apply"
  task :noopply => :noop_apply

  desc "applies the current puppet config to the server"
  task :apply do
    begin
      on roles(:puppet) do
        lock
        prepare
      end
      run_locally do
        update_code
      end
      on roles(:puppet) do
        puppet(:apply)
      end
    ensure
      on roles(:puppet) do
        unlock
      end
    end
  end

  desc "clears the puppet lockfile on the server."
  task :remove_lock do
    on roles(:puppet) do
      warn "WARNING: puppet:remove_lock is deprecated, please use puppet:unlock instead"
      unlock
    end
  end

  desc "clears the puppet lockfile on the server."
  task :unlock do
    on roles(:puppet) do
      unlock
    end
  end

  private

  def update_code
    SupplyDrop::Util.thread_pool_size = fetch(:puppet_parallel_rsync_pool_size)
    servers = SupplyDrop::Util.optionally_async(roles(:puppet), fetch(:puppet_parallel_rsync))
    failed_servers = servers.map do |server|
      # We have to manually build the ssh_options because we cannot use sshkit
      # for parallelizing local commands. Instead we use threads
      overrides = {
        :hostname => server.hostname,
        :port     => server.port ||= fetch(:port),
        :user     => server.user ||= fetch(:user, ENV['PUPPET_USER'])
      }.select {|_,v| v }
      puts overrides
      rsync_cmd = SupplyDrop::Rsync.command(
        fetch(:puppet_source),
        fetch(:puppet_destination),
        :excludes => fetch(:puppet_excludes),
        :includes => fetch(:puppet_includes),
        :ssh      => fetch(:ssh_options, {}).merge(server.ssh_options||{}).merge(overrides)
      )
      info rsync_cmd
      server.hostname unless system rsync_cmd
    end.compact

    raise "rsync failed on #{failed_servers.join(',')}" if failed_servers.any?
  end

  def prepare
    execute :mkdir, "-p #{fetch(:puppet_destination)}"
    sudo :chown, "-R $USER: #{fetch(:puppet_destination)}"
  end

  def apply
    puppet(:apply)
  end

  def lock
    if should_lock?
      execute <<-CHECK_LOCK
if [ -f #{fetch(:puppet_lock_file)} ]; then stat -c "#{red_text("Puppet in progress, #{fetch(:puppet_lock_file)} owned by %U since %x")}" #{fetch(:puppet_lock_file)} >&2
exit 1
fi
echo 'ok'
exit 0
      CHECK_LOCK

      execute :touch, "#{fetch(:puppet_lock_file)}"
    end
  end

  def unlock
    sudo :rm, "-f #{fetch(:puppet_lock_file)}; true" if should_lock?
  end

  def should_lock?
    fetch(:puppet_lock_file) && !ENV['NO_PUPPET_LOCK']
  end

  def puppet(command = :noop)
    puppet_cmd = "#{fetch(:puppet_command)} --modulepath=#{fetch(:puppet_lib)} #{fetch(:puppet_parameters)}"
    flag = command == :noop ? '--noop' : ''

    within fetch(:puppet_destination) do
      begin
        sudo "#{puppet_cmd} #{flag}"
        info "Puppet #{command} complete."
      rescue
        error "Puppet #{command} failed."
      end
    end
  end

  def red_text(text)
    "\033[0;31m#{text}\033[0m"
  end
end
