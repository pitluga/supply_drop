require 'supply_drop/rsync'
require 'supply_drop/async_enumerable'
require 'supply_drop/syntax_checker'
require 'supply_drop/thread_pool'
require 'supply_drop/util'
require 'supply_drop/writer/batched'
require 'supply_drop/writer/file'
require 'supply_drop/writer/streaming'

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
      servers = SupplyDrop::Util.optionally_async(find_servers_for_task(current_task), puppet_parallel_rsync)
      failed_servers = servers.map do |server|
        rsync_cmd = SupplyDrop::Rsync.command(
          puppet_source,
          SupplyDrop::Rsync.remote_address(server.user || fetch(:user, ENV['USER']), server.host, puppet_destination),
          :delete => true,
          :excludes => puppet_excludes,
          :world_writable => true,
          :ssh => { :keys => ssh_options[:keys], :config => ssh_options[:config], :port => fetch(:port, nil) }
        )
        logger.debug rsync_cmd
        server.host unless system rsync_cmd
      end.compact

      raise "rsync failed on #{failed_servers.join(',')}" if failed_servers.any?
    end

    before :'puppet:update_code' do
      syntax_check if puppet_syntax_check
      _set_threadpool_size
    end

    before 'puppet:noop' do
      _lock if _should_lock?
    end

    before 'puppet:apply' do
      _lock if _should_lock?
    end

    desc "runs puppet with --noop flag to show changes"
    task :noop, :except => { :nopuppet => true } do
      transaction do
        on_rollback { _unlock }
        update_code
        _puppet :noop
      end
    end

    desc "applies the current puppet config to the server"
    task :apply, :except => { :nopuppet => true } do
      transaction do
        on_rollback { _unlock }
        update_code
        _puppet :apply
      end
    end

    desc "clears the puppet lockfile on the server."
    task :remove_lock, :except => { :nopuppet => true} do
      _unlock
    end

    after 'puppet:noop' do
      _unlock
    end

    after 'puppet:apply' do
      _unlock
    end
  end

  def _set_threadpool_size
    SupplyDrop::Util.thread_pool_size = puppet_parallel_rsync_pool_size
  end

  def _red_text(text)
    "\033[0;31m#{text}\033[0m"
  end

  def _lock
    if puppet_lock_file
      run <<-GETLOCK
if [ ! -f #{puppet_lock_file} ]; then
    touch #{puppet_lock_file};
    mkdir -p #{puppet_destination};
    chmod o+w #{puppet_destination};
else
    stat -c "#{_red_text("Puppet in progress, #{puppet_lock_file} owned by %U since %x")}" #{puppet_lock_file} >&2;
    exit 1;
fi
      GETLOCK
    end
  end

  def _unlock
    run "rm -f #{puppet_lock_file}; true" if _should_lock?
  end

  def _should_lock?
    puppet_lock_file && !ENV['NO_PUPPET_LOCK']
  end

  def _puppet(command = :noop)
    puppet_cmd = "cd #{puppet_destination} && #{_sudo_cmd} #{puppet_command} --modulepath=#{puppet_lib} #{puppet_parameters}"
    flag = command == :noop ? '--noop' : ''

    writer = if puppet_stream_output
               SupplyDrop::Writer::Streaming.new(logger)
             else
               SupplyDrop::Writer::Batched.new(logger)
             end

    writer = SupplyDrop::Writer::File.new(writer, puppet_write_to_file) unless puppet_write_to_file.nil?

    begin
      run "#{puppet_cmd} #{flag}" do |channel, stream, data|
        writer.collect_output(channel[:host], data)
      end
      logger.debug "Puppet #{command} complete."
    ensure
      writer.all_output_collected
    end
  end

  def _sudo_cmd
    if fetch(:use_sudo, true)
      sudo(:as => puppet_runner)
    else
      logger.info "NOTICE: puppet_runner configuration invalid when use_sudo is false, ignoring..." unless puppet_runner.nil?
      ''
    end
  end
end
