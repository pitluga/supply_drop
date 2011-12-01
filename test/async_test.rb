require 'test/unit'
require File.expand_path('../../lib/supply_drop/util', __FILE__)
require File.expand_path('../../lib/supply_drop/async_enumerable', __FILE__)

class AsyncTest < Test::Unit::TestCase

  def test_can_enumerate_asynchronously
    collection = (1..10).to_a
    elapsed = timed do
      SupplyDrop::Util.optionally_async(collection, true).each do |item|
        sleep 0.1
      end
    end
    assert elapsed < 1
  end

  def test_can_enumerate_normally
    collection = (1..10).to_a
    elapsed = timed do
      SupplyDrop::Util.optionally_async(collection, false).each do |item|
        sleep 0.1
      end
    end
    assert elapsed >= 1
  end

  def timed
    start = Time.now
    yield
    Time.now - start
  end
end
