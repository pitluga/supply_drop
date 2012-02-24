module SupplyDrop
  module Writer
    class Streaming
      def initialize(logger)
        @logger = logger
      end

      def collect_output(host, data)
        @logger.debug data, host
      end

      def all_output_collected
      end
    end
  end
end
