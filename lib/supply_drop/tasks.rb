Capistrano::Configuration.instance.load do
  namespace :puppet do
    set :puppet_source, '.'
    set :puppet_destination, '/tmp/supply_drop'
    set :puppet_command, 'puppet apply'
    set :puppet_lib, lambda { "#{puppet_destination}/modules" }
    set :puppet_parameters, lambda { puppet_verbose ? '--debug --trace puppet.pp' : 'puppet.pp' }
    set :puppet_verbose, false
    set :puppet_excludes, %w(.git .svn)
    set :puppet_stream_output, false
    set :puppet_parallel_rsync, true
    set :puppet_parallel_rsync_pool_size, 10
    set :puppet_syntax_check, false
    set :puppet_write_to_file, nil
    set :puppet_runner, nil
    set :puppet_lock_file, '/tmp/puppet.lock'

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

      desc "installs puppet via yum on a centos/red hat host"
      task :redhat do
        run "mkdir -p #{puppet_destination}"
        run "#{sudo} yum -y install puppet rsync"
      end
    end

    desc "checks the syntax of all *.pp and *.erb files"
    task :syntax_check do
      checker = SupplyDrop::SyntaxChecker.new(puppet_source)
      logger.info "Sytax Checking..."
      errors = false
      checker.validate_puppet_files.each do |file, error|
        logger.important "Puppet error: #{file}"
        logger.important error
        errors = true
      end
      checker.validate_templates.each do |file, error|
        logger.important "Template error: #{file}"
        logger.important error
        errors = true
      end
      raise "syntax errors" if errors
    end

    desc "pushes the current puppet configuration to the server"
    task :update_code, :except => { :nopuppet => true } do
      syntax_check if puppet_syntax_check
      supply_drop.rsync
    end

    desc "runs puppet with --noop flag to show changes"
    task :noop, :except => { :nopuppet => true } do
      transaction do
        on_rollback { supply_drop.unlock }
        supply_drop.prepare
        supply_drop.lock
        update_code
        supply_drop.noop
        supply_drop.unlock
      end
    end

    desc "applies the current puppet config to the server"
    task :apply, :except => { :nopuppet => true } do
      transaction do
        on_rollback { supply_drop.unlock }
        supply_drop.prepare
        supply_drop.lock
        update_code
        supply_drop.apply
        supply_drop.unlock
      end
    end

    desc "clears the puppet lockfile on the server."
    task :remove_lock, :except => { :nopuppet => true} do
      supply_drop.lock
    end
  end
end

