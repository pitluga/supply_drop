require 'test/unit'
require File.expand_path('../../lib/supply_drop/util', __FILE__)
require File.expand_path('../../lib/supply_drop/async_enumerable', __FILE__)
require File.expand_path('../../lib/supply_drop/thread_pool', __FILE__)

class AsyncTest < Test::Unit::TestCase
  def teardown
    SupplyDrop::Util.thread_pool_size = SupplyDrop::Util::DEFAULT_THREAD_POOL_SIZE
  end

  def test_can_enumerate_asynchronously
    collection = (1..10).to_a
    elapsed = timed do
      SupplyDrop::Util.optionally_async(collection, true).each do |item|
        sleep 0.1
      end
    end
    assert elapsed < 1
  end

  def test_can_enumerate_asynchronously_with_map
    collection = (1..10).to_a
    returned_values = nil
    elapsed = timed do
      returned_values = SupplyDrop::Util.optionally_async(collection, true).map do |item|
        sleep 0.1
        :somevalue
      end
    end
    assert returned_values == Array.new(10, :somevalue)
    assert elapsed < 1
  end

  def test_can_enumerate_normally_and_does_not_leak_after_extending
    collection = (1..10).to_a
    elapsed = timed do
      SupplyDrop::Util.optionally_async(collection, true).each do |item|
        sleep 0.1
      end
    end
    assert elapsed < 1

    elapsed = timed do
      SupplyDrop::Util.optionally_async(collection, false).each do |item|
        sleep 0.1
      end
    end
    assert elapsed >= 1
  end

  def test_can_configure_thread_pool_size
    collection = (1..10).to_a
    SupplyDrop::Util.thread_pool_size = 1
    elapsed = timed do
      returned_values = SupplyDrop::Util.optionally_async(collection, true).map do |item|
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
