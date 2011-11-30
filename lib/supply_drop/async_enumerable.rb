module SupplyDrop
  module AsyncEnumerable
    def each(&block)
      self.map do |item|
        Thread.new { block.call(item) }
      end.each(&:join)
    end
  end
end
