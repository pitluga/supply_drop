set :ssh_options, {
  keys: ["#{ENV['HOME']}/.vagrant.d/insecure_private_key"],
  paranoid: false,
  keys_only: true,
  user_known_hosts_file: [],
  # verbose: :debug,
  config: false,
}
server '127.0.0.1', roles: %w(web app puppet), port: 2200, user: 'vagrant'
