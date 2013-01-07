module SupplyDrop
  module Plugin

    def rsync
      SupplyDrop::Util.thread_pool_size = puppet_parallel_rsync_pool_size
      servers = SupplyDrop::Util.optionally_async(find_servers_for_task(current_task), puppet_parallel_rsync)
      overrides = {}
      overrides[:user] = fetch(:user, ENV['USER'])
      overrides[:port] = fetch(:port) if exists?(:port)
      failed_servers = servers.map do |server|
        rsync_cmd = SupplyDrop::Rsync.command(
          puppet_source,
          SupplyDrop::Rsync.remote_address(server.user || fetch(:user, ENV['USER']), server.host, puppet_destination),
          :delete => true,
          :excludes => puppet_excludes,
          :ssh => ssh_options.merge(server.options[:ssh_options]||{}).merge(overrides)
        )
        logger.debug rsync_cmd
        server.host unless system rsync_cmd
      end.compact

      raise "rsync failed on #{failed_servers.join(',')}" if failed_servers.any?
    end

    def prepare
      run "mkdir -p #{puppet_destination}"
      run "#{sudo} chown -R $USER: #{puppet_destination}"
    end

    def noop
      puppet(:noop)
    end

    def apply
      puppet(:apply)
    end

    def lock
      if should_lock?
        run <<-GETLOCK
if [ ! -f #{puppet_lock_file} ]; then
    touch #{puppet_lock_file};
else
    stat -c "#{red_text("Puppet in progress, #{puppet_lock_file} owned by %U since %x")}" #{puppet_lock_file} >&2;
    exit 1;
fi
        GETLOCK
      end
    end

    def unlock
      run "#{sudo} rm -f #{puppet_lock_file}; true" if should_lock?
    end

    private

    def should_lock?
      puppet_lock_file && !ENV['NO_PUPPET_LOCK']
    end

    def puppet(command = :noop)
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

    def red_text(text)
      "\033[0;31m#{text}\033[0m"
    end

    def sudo_cmd
      if fetch(:use_sudo, true)
        sudo(:as => puppet_runner)
      else
        logger.info "NOTICE: puppet_runner configuration invalid when use_sudo is false, ignoring..." unless puppet_runner.nil?
        ''
      end
    end
  end
end
