# requires:
# vagrant plugin install landrush
# vagrant plugin install vagrant-omnibus
# vagrant plugin install vagrant-berkshelf

CHEF_VERSION = '11.8.2'
DEFAULT_VIRTUALBOX_OS = 'ubuntu1204'
DEFAULT_VIRTUALBOX_OS_URL = 'http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04_chef-provisionerless.box'

DEFAULT_VMWARE_OS = 'ubuntu1204vmware'
DEFAULT_VMWARE_OS_URL = 'http://opscode-vm-bento.s3.amazonaws.com/vagrant/vmware/opscode_ubuntu-12.04_chef-provisionerless.box'

upgrade_servers = 1.times.map { |i| "up#{i}" }
etcd_servers = 1.times.map { |i| "etcd#{i}" }

chef_formatter = ENV.fetch("CHEF_FORMAT", "null").downcase.to_sym
chef_loglevel = ENV.fetch("CHEF_LOG", "info").downcase.to_sym

def LoadProvider(node)
  node.vm.provider "virtualbox" do |v,o|
    o.vm.box = DEFAULT_VIRTUALBOX_OS
    o.vm.box_url = DEFAULT_VIRTUALBOX_OS_URL
  end
  node.vm.provider "vmware_fusion" do |v,o|
    o.vm.box = DEFAULT_VMWARE_OS
    o.vm.box_url = DEFAULT_VMWARE_OS_URL
  end
end

Vagrant.configure('2') do |config|
  dev_dir = ENV["VIRGO_VAGRANT_DEV"] || "#{ENV['HOME']}/Development"

  config.vm.synced_folder dev_dir, "/data/dev", type: "nfs"
  config.ssh.forward_agent = true

  config.landrush.enable

  config.berkshelf.enabled = true
  config.berkshelf.berksfile_path = 'cookbooks/Berksfile'

  upgrade_servers.each_index do |index|
    config.vm.define upgrade_servers[index] do |node_config|
      LoadProvider(node_config)
      node_config.omnibus.chef_version = CHEF_VERSION
      node_config.vm.hostname = "up#{index}.vagrant.dev"
      node_config.vm.provision :chef_solo do |chef|
        chef.formatter = chef_formatter
        chef.log_level = chef_loglevel
        chef.run_list = [
          "recipe[virgo-update-service]"
        ]
      end
    end
  end

  etcd_servers.each_index do |index|
    config.vm.define etcd_servers[index] do |node_config|
      LoadProvider(node_config)
      node_config.vm.hostname = "etcd#{index}.vagrant.dev"
      node_config.omnibus.chef_version = CHEF_VERSION
      node_config.vm.provision :chef_solo do |chef|
        chef.formatter = chef_formatter
        chef.log_level = chef_loglevel
        chef.run_list = [
          "recipe[etcd]"
        ]
      end
    end
  end
end
