require 'test/unit'
require File.expand_path('../../lib/supply_drop/rsync', __FILE__)

class RsyncTest < Test::Unit::TestCase

  def test_build_simple_command
    command = Rsync.command('bar', 'foo')
    assert_equal 'rsync -az bar foo', command
  end

  def test_allows_passing_delete
    command = Rsync.command('bar', 'foo', :delete => true)
    assert_equal 'rsync -az --delete bar foo', command
  end

  def test_allows_specifying_an_exclude
    command = Rsync.command('bar', 'foo', :excludes => '.git')
    assert_equal 'rsync -az --exclude=.git bar foo', command
  end

  def test_ssh_options_keys_only_lists_existing_files
    command = Rsync.command('.', 'foo', :ssh => { :keys => [__FILE__, "#{__FILE__}dadijofs"] })
    assert_match /-i #{__FILE__}/, command
  end

  def test_ssh_options_ignores_keys_if_nil
    command = Rsync.command('.', 'foo', :ssh => { :keys => nil })
    command = Rsync.command('bar', 'foo')
    assert_equal 'rsync -az bar foo', command
  end
end
