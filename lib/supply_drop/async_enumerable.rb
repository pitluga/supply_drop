module SupplyDrop
  module AsyncEnumerable
    def each(&block)
      pool = SupplyDrop::ThreadPool.new(SupplyDrop::Util.thread_pool_size)
      super do |item|
        pool.schedule(item, &block)
      end
      pool.shutdown
    end

    def map(&block)
      pool = SupplyDrop::ThreadPool.new(SupplyDrop::Util.thread_pool_size)
      super do |item|
        pool.schedule(item, &block)
      end
      pool.shutdown
    end
  end
end
