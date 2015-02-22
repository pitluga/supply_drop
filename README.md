# supply_drop

*THIS IS THE DOCUMENTATION FOR THE 1.x VERSION OF SUPPLY DROP THAT IS COMPATIBLE WITH CAPISTRANO 3.x. 0.x [docs](https://github.com/pitluga/supply_drop/tree/cap-2x) available on the cap-2x branch*

supply_drop is a capistrano plugin to facitiate provisioning servers with puppet, without using the puppet server. It works by simply rsyncing your puppet configuration files to your servers and running puppet apply. It strives to allow you to write idiomatic puppet scripts while being as lightweight as possible.

[![Build Status](https://secure.travis-ci.org/pitluga/supply_drop.png)](http://travis-ci.org/pitluga/supply_drop)

### Installation

    gem install supply_drop

or with Bundler

    gem 'supply_drop'

then add the following to your Capfile

    require 'supply_drop'

### Tasks

    cap staging puppet:bootstrap:debian
    cap staging puppet:bootstrap:ubuntu
    cap staging puppet:bootstrap:osx
    cap staging puppet:bootstrap:redhat

This does a simple apt-get install of puppet on the target servers.

    cap staging puppet:bootstrap:puppetlabs:debian
    cap staging puppet:bootstrap:puppetlabs:ubuntu

This is the same as above, but it grabs the most recent versions of puppet via apt repositories provided by puppetlabs.

    cap staging puppet:noop

This will show you a list of the pending changes to be applied server-by-server.

    cap staging puppet:apply

Applies the pending changes to all the servers.

    cap staging puppet:unlock

Remove any stale lock files created by supply_drop when locking is used and something went wrong.


Only servers in the puppet role will be puppeted.

    role :puppet, '33.33.33.33'

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

    set :puppet_parallel_rsync_pool_size, 10

sets the maximum number of rsync commands that are run concurrently

    set :puppet_lock_file, '/tmp/puppet.lock'

sets a lockfile on each remote host to prevent multiple users from puppeting the same node simultaneously. Set to nil to disable locking. You can alternately temporarily disable locking by setting the NO_PUPPET_LOCKING environment variable to any value.

### Handling Legacy Puppet

Puppet deprecated the implicit invocation of apply [in the 2.6.x series](https://github.com/puppetlabs/puppet/commit/a23cfd869f90ae4456dded6e5a1c82719b128f01).

The default behavior of supply_drop includes `apply` keyword in its commands, but if you need compatibility with older versions of puppet, set the `puppet_command` variable to omit it.

You'll need to do this if you see errors like this:

    Could not parse for environment production: Could not find file /home/.../supply_drop/apply.pp

### Hiera support

Most distributions don't package versions of puppet that are new enough to support hiera. Use the puppetlabs namespaced bootstrap tasks above to make sure you get hiera support.

### How to contribute

If you write anything complicated, write a test for it. Test that your changes work using vagrant. Send a pull request. Easy peezy.

### Contributors

* Paul Hinze [phinze](https://github.com/phinze "github")
* Paul Gross [pgr0ss](https://github.com/pgr0ss "github")
* Drew Olson [drewolson](https://github.com/drewolson "github")
* Dave Pirotte [dpirotte](https://github.com/dpirotte "github")
* Mike Pilat [mikepilat](https://github.com/mikepilat "github")
* Dan Manges [dan-manges](https://github.com/dan-manges "github") (one soda's worth)
* Brian Cosgrove [cosgroveb](https://github.com/cosgroveb "github")
* Troy Howard [thoward](https://github.com/thoward "github")

Copyright (c) 2012-2013 Tony Pitluga

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
