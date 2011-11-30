module SupplyDrop
  module AsyncEnumerable
    def each(collection, &block)
      collection.map do |item|
        Thread.new { block.call(item) }
      end.each(&:join)
    end
  end
end
