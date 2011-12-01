module SupplyDrop
  module Util
    def self.optionally_async(collection, async)
      if async
        collection.extend SupplyDrop::AsyncEnumerable
      else
        collection
      end
    end
  end
end
