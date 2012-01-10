module SupplyDrop
  module AsyncEnumerable
    def each(&block)
      threads = []
      super do |item|
        threads << Thread.new { block.call(item) }
      end
      threads.each(&:join)
    end

    def map(&block)
      super do |item|
        Thread.new { Thread.current[:output] = block.call(item) }
      end.map(&:join).map { |t| t[:output] }
    end
  end
end
