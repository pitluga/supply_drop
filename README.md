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

    cap puppet:bootstrap:ubuntu
    cap puppet:bootstrap:osx
    cap puppet:bootstrap:redhat

This does a simple apt-get install of puppet on the target servers.

    cap puppet:noop

This will show you a list of the pending changes to be applied server-by-server.

    cap puppet:apply

Applies the pending changes to all the servers.

    cap puppet:syntax_check

Locally syntax checks all the puppet files and erb templates. Requires you to have puppet installed locally.


You can specify that one of your servers should not be puppeted by setting the :nopuppet flag to true, like so. It will then be skipped by all the above commands.

    role :weird_thing, '33.33.33.33', :nopuppet => true

### Variables

There are several variables that can be overriden to change how supply_drop works:

    set :puppet_source, '.'

defines the base directory containing your puppet configs that will be rsynced to the servers.

    set :puppet_destination, '/tmp/supply_drop'

defines where on the server the puppet configuration files are synced to.

    set :puppet_command, 'puppet apply'

allows you to override the puppet command that is run if puppet is not on the path.

    set :puppet_lib, "#{puppet_destination}/modules"

the value of the PUPPETLIB environment variable, the location of your puppet modules.

    set :puppet_parameters, 'puppet.pp'

the parameters that are passed to the puppet call.

    set :puppet_excludes, %w(.git .svn)

these are patterns that are passed as rsync --exclude flags when pushing your puppet configs to the box.

    set :puppet_parallel_rsync, true

determines whether the rsync commands for multiple servers are run in parallel threads or serially

    set :puppet_syntax_check, true

when true, will syntax check your puppet files and erb templates before rsyncing them to your servers.

### Handling Legacy Puppet

Puppet deprecated the implicit invocation of apply [in the 2.6.x series](https://github.com/puppetlabs/puppet/commit/a23cfd869f90ae4456dded6e5a1c82719b128f01).

The default behavior of supply_drop includes `apply` keyword in its commands, but if you need compatibility with older versions of puppet, set the `puppet_command` variable to omit it.

You'll need to do this if you see errors like this:

    Could not parse for environment production: Could not find file /home/.../supply_drop/apply.pp

### How to contribute

If you write anything complicated, write a test for it. Test that your changes work using vagrant. Send a pull request. Easy peezy.

### Contributors

* Paul Hinze [phinze](https://github.com/phinze "github")
* Paul Gross [pgr0ss](https://github.com/pgr0ss "github")
* Drew Olson [drewolson](https://github.com/drewolson "github")
* Dave Pirotte [dpirotte](https://github.com/dpirotte "github")
* Dan Manges [dan-manges](https://github.com/dan-manges "github") (one soda's worth)
