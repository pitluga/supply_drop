class Rsync
  class << self
    def command(from, to, options={})
      flags = ['-az']
      flags << '--delete' if options[:delete]
      flags << excludes(options[:excludes]) if options.has_key?(:excludes)
      flags << ssh_options(options[:ssh]) if options.has_key?(:ssh)

      "rsync #{flags.compact.join(' ')} #{from} #{to}"
    end

    def remote_address(user, host, path)
      user_with_host = [user, host].compact.join('@')
      [user_with_host, path].join(':')
    end

    def excludes(patterns)
      [patterns].flatten.map { |p| "--exclude=#{p}" }
    end

    def ssh_options(options)
      mapped_options = options.map do |key, value|
        if key == :keys && value != nil
          [value].flatten.select { |k| File.exist?(k) }.map { |k| "-i #{k}" }
        end
      end

      %[-e "ssh #{mapped_options.join(' ')}"]
    end
  end
end
