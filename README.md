# supply_drop

supply_drop is a capistrano plugin to facitiate provisioning servers with puppet, without using the puppet server. It works by simply rsyncing your puppet configuration files to your servers and running puppet apply. It strives to allow you to write idiomatic puppet scripts while being as lightweight as possible.

### Installation

    gem install supply_drop

or with Bundler

    gem 'supply_drop'

then at the top of your deploy.rb

    require 'rubygems'
    require 'supply_drop'

### Tasks

    cap puppet:bootstrap

This does a simple apt-get install of puppet on the target servers.

    cap puppet:noop

This will show you a list of the pending changes to be applied server-by-server.

    cap puppet:apply

Applies the pending changes to all the servers.

You can specify that one of your servers should be puppet by setting the :nopuppet flag to true, like so. It will then be skipped by all the above commands.

    role :weird_thing, '33.33.33.33', :nopuppet => true

### Variables

There are several variables that can be overriden to change how supply_drop works:

    set :puppet_source, '.'

defines the base directory containing your puppet configs that will be rsynced to the servers.

    set :puppet_destination, '/tmp/supply_drop'

defines where on the server the puppet configuration files are synced to.

    set :puppet_command, 'puppet'

allows you to override the puppet command that is run if puppet is not on the path.

    set :puppet_lib, "#{puppet_destination}/modules"

the value of the PUPPETLIB environment variable, the location of your puppet modules

    set :puppet_parameters, 'puppet.pp'

the parameters that are passed to the puppet call.

### How to contribute

If you write anything complicated, write a test for it. Test that your changes work using vagrant. Send a pull request. Easy peezy.

### Contributors

* Paul Gross [pgr0ss](https://github.com/pgr0ss "github")
* Drew Olson [drewolson](https://github.com/drewolson "github")
