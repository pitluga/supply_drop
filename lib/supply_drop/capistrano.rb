Capistrano::Configuration.instance.load do
  namespace :puppet do
    task :bootstrap, :only => { :puppet => true } do
      run "#{sudo} apt-get update"
      run "#{sudo} apt-get install -y puppet"
    end

    task :update_code, :only => { :puppet => true } do
      system "tar zcf supply_drop.tgz --exclude supply_drop.tgz --exclude '.vagrant' --exclude '*.deb' --exclude '.git' ."
      run "if [ -d ~/supply_drop ]; then rm -r ~/supply_drop; fi && mkdir supply_drop"
      upload "supply_drop.tgz", "supply_drop/supply_drop.tgz", :via => :scp
      system "rm supply_drop.tgz"
      run "cd supply_drop && tar xzf supply_drop.tgz"
    end

    task :noop, :only => { :puppet => true } do
      update_code
      puppet :noop
    end

    task :apply, :only => { :puppet => true } do
      update_code
      puppet :apply
    end
  end

  def puppet(command = :noop)
    flag = command == :noop ? '--noop' : ''
    roles.keys.each do |role_name|
      parallel do |session|
        session.when "in?(:#{role_name}) && server.options[:puppet]","PUPPETLIB=~/supply_drop/modules puppet #{flag} supply_drop/roles/#{role_name}.pp" 
      end
    end
  end
end
