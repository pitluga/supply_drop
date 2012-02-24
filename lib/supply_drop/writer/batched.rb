module SupplyDrop
  module Writer
    class Batched
      def initialize(logger)
        @outputs = {}
        @logger = logger
      end

      def collect_output(host, data)
        @outputs[host] ||= ""
        @outputs[host] << data
      end

      def all_output_collected
        @outputs.keys.sort.each do |host|
          @logger.info "Puppet output for #{host}"
          @logger.debug @outputs[host], host
        end
      end
    end
  end
end
