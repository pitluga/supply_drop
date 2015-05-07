module SupplyDrop
  class Rsync
    class << self
      def command(from, to, options={})
        # Other methods rely upon options[:ssh] not being nil
        options.merge!(:ssh => {}) unless options[:ssh]

        # --delete will remove files on 'to' that don't exist on 'from'
        flags = ['-az', '--delete']
        flags << [options[:excludes]].flatten.compact.map { |p| "--exclude=#{p}" }
        flags << ssh_options(options[:ssh])

        # While extra whitespace won't affect the rsync command it does break tests
        flags.reject!(&:empty?)

        "rsync #{flags.join(' ')} #{from} #{remote_address(to, options[:ssh])}"
      end

      def remote_address(to, ssh_opts)
        user_with_host = [ssh_opts[:user], ssh_opts[:hostname]].compact.join('@')
        [user_with_host, to].reject(&:empty?).join(':')
      end

      #
      # Convert Net::SSH options into OpenSSH options.
      #
      # For a list of the options normally support by Net::SSH (and thus Capistrano), see
      # http://net-ssh.github.com/net-ssh/classes/Net/SSH.html#method-c-start
      #
      # Also, to see how Net::SSH does the opposite of the conversion we are doing here, check out:
      # https://github.com/net-ssh/net-ssh/blob/master/lib/net/ssh/config.rb
      #
      # API mismatch:
      #
      # * many OpenSSH options not supported
      # * some options only make sense for Net::SSH
      # * compression: for Net::SSH, this option is supposed to accept true, false, or algorithm. OpenSSH accepts 'yes' or 'no'
      #
      def ssh_options(options)
        mapped_options = options.map do |key, value|
          next if value.nil?

          case key
          when :auth_methods            then opt_auth_methods(value)
          when :bind_address            then opt('BindAddress', value)
          when :compression             then opt('Compression', value ? 'yes' : 'no')
          when :compression_level       then opt('CompressionLevel', value.to_i)
          when :config                  then value ? "-F '#{value}'" : nil
          when :encryption              then opt('Ciphers', [value].flatten.join(','))
          when :forward_agent           then opt('ForwardAgent', value)
          when :global_known_hosts_file then opt('GlobalKnownHostsFile', value)
          when :hmac                    then opt('MACs', [value].flatten.join(','))
          when :host_key                then opt('HostKeyAlgorithms', [value].flatten.join(','))
          when :host_key_alias          then opt('HostKeyAlias', value)
          when :host_name               then opt('HostName', value)
          when :kex                     then opt('KexAlgorithms', [value].flatten.join(','))
          when :key_data                then nil # not supported
          when :keys                    then [value].flatten.select { |k| File.exist?(k) }.map { |k| "-i '#{k}'" }
          when :keys_only               then opt('IdentitiesOnly', value ? 'yes' : 'no')
          when :languages               then nil # not applicable
          when :logger                  then nil # not applicable
          when :paranoid                then opt('StrictHostKeyChecking', value ? 'yes' : 'no')
          when :passphrase              then nil # not supported
          when :password                then nil # not supported
          when :port                    then "-p #{value.to_i}"
          when :properties              then nil # not applicable
          when :proxy                   then nil # not applicable
          when :rekey_blocks_limit      then nil # not supported
          when :rekey_limit             then opt('RekeyLimit', reverse_interpret_size(value))
          when :rekey_packet_limit      then nil # not supported
          when :timeout                 then opt('ConnectTimeout', value.to_i)
          when :user                    then "-l #{value}"
          when :user_known_hosts_file   then multi_opt('UserKnownHostsFile', value)
          when :verbose                 then opt('LogLevel', interpret_log_level(value))
          end
        end.compact

        mapped_options.empty? ? mapped_options : %[-e "ssh #{mapped_options.join(' ')}"]
      end

      private

      def opt(option_name, option_value)
        "-o #{option_name}='#{option_value}'"
      end

      def multi_opt(option_name, option_values)
        [option_values].flatten.map do |value|
          opt(option_name, value)
        end.join(' ')
      end

      #
      # In OpenSSH, password and pubkey default to 'yes', hostbased defaults to 'no'.
      # Regardless, if :auth_method is configured, then we explicitly disable methods not included.
      #
      def opt_auth_methods(value)
        value = [value].flatten
        opts = []
        if value.any?
          if value.include? 'password'
            opts << opt('PasswordAuthentication', 'yes')
          else
            opts << opt('PasswordAuthentication', 'no')
          end
          if value.include? 'publickey'
            opts << opt('PubkeyAuthentication', 'yes')
          else
            opts << opt('PubkeyAuthentication', 'no')
          end
          if value.include? 'hostbased'
            opts << opt('HostbasedAuthentication', 'yes')
          else
            opts << opt('HostbasedAuthentication', 'no')
          end
        end
        if opts.any?
          return opts.join(' ')
        else
          nil
        end
      end

      #
      # Converts the given integer size in bytes into a string with 'K', 'M', 'G' suffix, as appropriate.
      #
      # reverse of interpret_size in https://github.com/net-ssh/net-ssh/blob/master/lib/net/ssh/config.rb
      #
      def reverse_interpret_size(size)
        size = size.to_i
        if size < 1024
          "#{size}"
        elsif size < 1024 * 1024
          "#{size/1024}K"
        elsif size < 1024 * 1024 * 1024
          "#{size/(1024*1024)}M"
        else
          "#{size/(1024*1024*1024)}G"
        end
      end

      def interpret_log_level(level)
        if level.is_a? Symbol
          case level
            when :debug then "DEBUG"
            when :info then "INFO"
            when :warn then "ERROR"
            when :error then "ERROR"
            when :fatal then "FATAL"
            else "INFO"
          end
        elsif level.is_a? Integer
          case level
            when Logger::DEBUG then "DEBUG"
            when Logger::INFO then "INFO"
            when Logger::WARN then "ERROR"
            when Logger::ERROR then "ERROR"
            when Logger::FATAL then "FATAL"
            else "INFO"
          end
        else
          "INFO"
        end
      end

    end
  end
end
