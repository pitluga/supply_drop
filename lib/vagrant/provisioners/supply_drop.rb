module Vagrant
  module Provisioners
    class SupplyDrop < Base
      register :supply_drop

      class Config < Vagrant::Config::Base
        attr_accessor :role
      end

      def prepare
        env.config.vm.share_folder("supply_drop", "~/supply_drop", ".")
      end

      def provision!
        vm.ssh.execute do |ssh|
          # ssh.sudo!('apt-get update')
          # ssh.sudo!('apt-get install puppet -y')

          manifest = config.role.nil? ? 'manifest.pp' : "roles/#{config.role}.pp"

          puppet_apply = "PUPPETLIB=~/supply_drop/modules puppet supply_drop/#{manifest}"
          ssh.sudo!(puppet_apply) do |ch, type, data|
            if type == :exit_status
              ssh.check_exit_status(data, puppet_apply)
            else
              env.ui.info(data)
            end
          end
        end
      end

    end
  end
end
