CHEF_VERSION = '11.8.2'
DEFAULT_OS = 'ubuntu1204'

upgrade_servers = 2.times.map { |i| "up#{i}" }

Vagrant.configure('2') do |config|
  dev_dir = ENV["VIRGO_VAGRANT_DEV"] || "#{ENV['HOME']}/Development"

  config.vm.network "private_network", ip: "192.168.0.4"
  config.vm.synced_folder dev_dir, "/data/dev", type: "nfs"
  config.ssh.forward_agent = true

  config.landrush.enable

  config.berkshelf.enabled = true
  config.berkshelf.berksfile_path = 'cookbooks/Berksfile'

  upgrade_servers.each_index do |index|
    config.vm.define upgrade_servers[index] do |node_config|
      node_config.omnibus.chef_version = CHEF_VERSION
      node_config.vm.box = DEFAULT_OS
      node_config.vm.hostname = "upgrade#{index}.vagrant.dev"
      node_config.vm.provision :chef_solo do |chef|
        chef.formatter = ENV.fetch("CHEF_FORMAT", "null").downcase.to_sym
        chef.log_level = ENV.fetch("CHEF_LOG", "info").downcase.to_sym
        chef.run_list = [
          "recipe[virgo-update-service::default]"
        ]
      end
    end
  end
end
