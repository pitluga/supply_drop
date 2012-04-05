require 'supply_drop/rsync'
require 'supply_drop/async_enumerable'
require 'supply_drop/syntax_checker'
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
    set :puppet_syntax_check, false
    set :puppet_write_to_file, nil

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
          :ssh => { :keys => ssh_options[:keys], :config => ssh_options[:config], :port => fetch(:port, nil) }
        )
        logger.debug rsync_cmd
        server.host unless system rsync_cmd
      end.compact

      raise "rsync failed on #{failed_servers.join(',')}" if failed_servers.any?
    end

    before :'puppet:update_code' do
      syntax_check if puppet_syntax_check
    end

    desc "runs puppet with --noop flag to show changes"
    task :noop, :except => { :nopuppet => true } do
      update_code
      _puppet :noop
    end

    desc "applies the current puppet config to the server"
    task :apply, :except => { :nopuppet => true } do
      update_code
      _puppet :apply
    end
  end

  def _puppet(command = :noop)
    sudo_cmd = fetch(:use_sudo, true) ? sudo : ''
    puppet_cmd = "cd #{puppet_destination} && #{sudo_cmd} #{puppet_command} --modulepath=#{puppet_lib} #{puppet_parameters}"
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
end
