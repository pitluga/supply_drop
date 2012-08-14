module SupplyDrop
  module Util
    DEFAULT_THREAD_POOL_SIZE = 10

    def self.thread_pool_size
      @thread_pool_size ||= DEFAULT_THREAD_POOL_SIZE
    end

    def self.thread_pool_size=(size)
      @thread_pool_size = size
    end

    def self.optionally_async(collection, async)
      if async
        async_collection = collection.clone
        async_collection.extend SupplyDrop::AsyncEnumerable
        async_collection
      else
        collection
      end
    end
  end
end
