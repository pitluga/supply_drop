module SupplyDrop
  module Writer
    class File
      def initialize(writer, file)
        @wrapped_writer = writer
        @logger = Capistrano::Logger.new(:output => file)
        @logger.level = Capistrano::Logger::TRACE
        @file_writer = Batched.new(@logger)
      end

      def collect_output(host, data)
        @wrapped_writer.collect_output(host, data)
        @file_writer.collect_output(host, data)
      end

      def all_output_collected
        @wrapped_writer.all_output_collected
        @file_writer.all_output_collected
        @logger.close
      end
    end
  end
end
