# -*- mode: ruby -*-
# vi: set ft=ruby :

BOX_NAME = ENV['BOX_NAME'] || "opscode-ubuntu-1310"
BOX_URI = ENV['BOX_URI'] || "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-13.10_chef-provisionerless.box"
VF_BOX_URI = ENV['BOX_URI'] || "http://opscode-vm-bento.s3.amazonaws.com/vagrant/vmware/opscode_ubuntu-13.10_chef-provisionerless.box"
AWS_REGION = ENV['AWS_REGION']
AWS_AMI    = ENV['AWS_AMI']

Vagrant::Config.run do |config|
  # Setup virtual machine box. This VM configuration code is always executed.
  config.vm.box = BOX_NAME
  config.vm.box_url = BOX_URI

  # Docker Registry
  config.vm.forward_port 5000, 15000

  # Shipyard
  config.vm.forward_port 8005, 18005

  # blueflood
  config.vm.forward_port 7000, 17000
  config.vm.forward_port 7001, 17001
  config.vm.forward_port 7199, 17199
  config.vm.forward_port 9160, 19160
  config.vm.forward_port 9042, 19042
  config.vm.forward_port 19000, 19000
  config.vm.forward_port 20000, 20000

  # Provision docker and new kernel if deployment was not done.
  # It is assumed Vagrant can successfully launch the provider instance.
  if Dir.glob("#{File.dirname(__FILE__)}/.vagrant/machines/default/*/id").empty?
    # Add lxc-docker package
    pkg_cmd = "wget -q -O - https://get.docker.io/gpg | apt-key add -;" \
      "echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list;" \
      "apt-get update -qq; apt-get install -q -y --force-yes lxc-docker; "
    pkg_cmd << "apt-get update -qq; apt-get clean;"
    pkg_cmd << "sudo usermod -a -G docker vagrant;"
    config.vm.provision :shell, :inline => pkg_cmd
  end
end


# Providers were added on Vagrant >= 1.1.0
Vagrant::VERSION >= "1.1.0" and Vagrant.configure("2") do |config|
  config.vm.provider :aws do |aws, override|
    aws.access_key_id = ENV["AWS_ACCESS_KEY_ID"]
    aws.secret_access_key = ENV["AWS_SECRET_ACCESS_KEY"]
    aws.keypair_name = ENV["AWS_KEYPAIR_NAME"]
    override.ssh.private_key_path = ENV["AWS_SSH_PRIVKEY"]
    override.ssh.username = "ubuntu"
    aws.region = AWS_REGION
    aws.ami    = AWS_AMI
    aws.instance_type = "m1.xlarge"
  end

  config.vm.provider :rackspace do |rs|
    config.ssh.private_key_path = ENV["RS_PRIVATE_KEY"]
    rs.username = ENV["RS_USERNAME"]
    rs.api_key  = ENV["RS_API_KEY"]
    rs.public_key_path = ENV["RS_PUBLIC_KEY"]
    rs.flavor   = /512MB/
    rs.image    = /Ubuntu/
  end

  config.vm.provider :vmware_fusion do |f, override|
    override.vm.box = BOX_NAME
    override.vm.box_url = VF_BOX_URI
    f.vmx["memsize"] = "2048"
    f.vmx["numvcpus"] = "2"
  end

  config.vm.provider :virtualbox do |vb|
    config.vm.box = BOX_NAME
    config.vm.box_url = BOX_URI
    #memory
    vb.customize ["modifyvm", :id, "--memory", "2048"]
  end
end
