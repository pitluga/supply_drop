require 'test/unit'
require File.expand_path('../../lib/supply_drop/rsync', __FILE__)

class RsyncTest < Test::Unit::TestCase

  def test_build_simple_command
    command = SupplyDrop::Rsync.command('bar', 'foo')
    assert_equal 'rsync -az bar foo', command
  end

  def test_allows_passing_delete
    command = SupplyDrop::Rsync.command('bar', 'foo', :delete => true)
    assert_equal 'rsync -az --delete bar foo', command
  end

  def test_allows_specifying_an_exclude
    command = SupplyDrop::Rsync.command('bar', 'foo', :excludes => '.git')
    assert_equal 'rsync -az --exclude=.git bar foo', command
  end

  def test_ssh_options_keys_only_lists_existing_files
    command = SupplyDrop::Rsync.command('.', 'foo', :ssh => { :keys => [__FILE__, "#{__FILE__}dadijofs"] })
    assert_match /-i #{__FILE__}/, command
  end

  def test_ssh_options_ignores_keys_if_nil
    command = SupplyDrop::Rsync.command('.', 'foo', :ssh => { :keys => nil })
    assert_equal 'rsync -az . foo', command
    command = SupplyDrop::Rsync.command('bar', 'foo')
    assert_equal 'rsync -az bar foo', command
  end

  def test_ssh_options_config_adds_flag
    command = SupplyDrop::Rsync.command('.', 'foo', :ssh => { :config => __FILE__ })
    assert_equal %Q[rsync -az -e "ssh -F #{__FILE__}" . foo], command
  end

  def test_ssh_options_port_adds_port
    command = SupplyDrop::Rsync.command('.', 'foo', :ssh => { :port => '30022' })
    assert_equal %Q[rsync -az -e "ssh -p 30022" . foo], command
  end

  def test_ssh_options_ignores_config_if_nil_or_false
    command = SupplyDrop::Rsync.command('.', 'foo', :ssh => { :config => nil })
    assert_equal 'rsync -az . foo', command
    command = SupplyDrop::Rsync.command('.', 'foo', :ssh => { :config => false })
    assert_equal 'rsync -az . foo', command
  end

  def test_remote_address_concatinates_things_correctly
    assert_equal "user@box.local:/tmp", SupplyDrop::Rsync.remote_address('user', 'box.local', '/tmp')
  end

  def test_remote_address_drops_at_when_user_is_nil
    assert_equal 'box.local:/tmp', SupplyDrop::Rsync.remote_address(nil, 'box.local', '/tmp')
  end
end
