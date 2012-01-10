module SupplyDrop
  module Util
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
