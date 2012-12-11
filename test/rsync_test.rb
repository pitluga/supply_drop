require 'test/unit'
require File.expand_path('../../lib/supply_drop/rsync', __FILE__)

if RUBY_VERSION >= '1.9'
  SimpleOrderedHash = ::Hash
else
  class SimpleOrderedHash < Hash
    def each; self.keys.map(&:to_s).sort.each {|key| yield [key.to_sym, self[key.to_sym]]}; end
  end
end

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
    assert_match /-i '#{__FILE__}'/, command
  end

  def test_ssh_options_ignores_keys_if_nil
    command = SupplyDrop::Rsync.command('.', 'foo', :ssh => { :keys => nil })
    assert_equal 'rsync -az . foo', command
    command = SupplyDrop::Rsync.command('bar', 'foo')
    assert_equal 'rsync -az bar foo', command
  end

  def test_ssh_options_config_adds_flag
    command = SupplyDrop::Rsync.command('.', 'foo', :ssh => { :config => __FILE__ })
    assert_equal %Q[rsync -az -e "ssh -F '#{__FILE__}'" . foo], command
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

  def test_simple_ssh_options
    options = SupplyDrop::Rsync.ssh_options(SimpleOrderedHash[
      :bind_address, '0.0.0.0',
      :compression, true,
      :compression_level, 1,
      :config, '/etc/ssh/ssh_config',
      :global_known_hosts_file, '/etc/ssh/known_hosts',
      :host_name, 'myhost',
      :keys_only, false,
      :paranoid, true,
      :port, 2222,
      :timeout, 10000,
      :user, 'root',
      :user_known_hosts_file, '~/.ssh/known_hosts'
    ])
    expecting = %q[-e "ssh -o BindAddress='0.0.0.0' -o Compression='yes' -o CompressionLevel='1' -F '/etc/ssh/ssh_config' -o GlobalKnownHostsFile='/etc/ssh/known_hosts' -o HostName='myhost' -o StrictHostKeyChecking='yes' -p 2222 -o ConnectTimeout='10000' -l root -o UserKnownHostsFile='~/.ssh/known_hosts'"]
    assert_equal expecting, options
  end

  def test_complex_ssh_options
    options = SupplyDrop::Rsync.ssh_options(SimpleOrderedHash[
      :auth_methods, 'publickey',
      :encryption, ['aes256-cbc', 'aes192-cbc'],
      :hmac, 'hmac-sha2-256',
      :host_key, 'ecdsa-sha2-nistp256-cert-v01@openssh.com',
      :rekey_limit, 2*1024*1024,
      :verbose, :debug,
      :user_known_hosts_file, ['~/.ssh/known_hosts', '~/.ssh/production_known_hosts']
    ])
    expecting = %q[-e "ssh -o PasswordAuthentication='no' -o PubkeyAuthentication='yes' -o HostbasedAuthentication='no' -o Ciphers='aes256-cbc,aes192-cbc' -o MACs='hmac-sha2-256' -o HostKeyAlgorithms='ecdsa-sha2-nistp256-cert-v01@openssh.com' -o RekeyLimit='2M' -o UserKnownHostsFile='~/.ssh/known_hosts' -o UserKnownHostsFile='~/.ssh/production_known_hosts' -o LogLevel='DEBUG'"]
    assert_equal expecting, options
  end

end
