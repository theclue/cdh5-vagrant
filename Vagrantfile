# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# Configuration parameters
managerRam = 2048                     # Ram in MB for the Cludera Manager Node
nodeRam = 1024                        # Ram in MB for each DataNode
nodeCount = 3                         # Number of DataNodes to create
privateNetworkIp = "10.10.50.5"       # Starting IP range for the private network between nodes
secondaryStorage = 80                 # Size in GB for the secondary virtual HDD

# Do not edit below this line
# --------------------------------------------------------------
privateSubnet = privateNetworkIp.split(".")[0...3].join(".")
privateStartingIp = privateNetworkIp.split(".")[3].to_i

# Create hosts data
  hosts = "#{privateSubnet}.#{privateStartingIp} cdh-master cdh-master\n"
  nodeCount.times do |i|
    id = i+1
    hosts << "#{privateSubnet}.#{privateStartingIp + id} cdh-node#{id} cdh-node#{id}\n"
  end

$hosts_data = <<SCRIPT
#!/bin/bash
cat > /etc/hosts <<EOF
127.0.0.1       localhost

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

#{hosts}
EOF
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "centos65-x86_64-20140116"
  config.vm.box_url = "https://github.com/2creatives/vagrant-centos/releases/download/v6.4.2/centos64-x86_64-20140116.box"
  config.vm.define "cdh-master" do |master|
    master.vm.network :public_network, :bridge => 'eth0'
    master.vm.network :private_network, ip: "#{privateSubnet}.#{privateStartingIp}", :netmask => "255.255.255.0", virtualbox__intnet: "cdhnetwork"
    master.vm.hostname = "cdh-master"

    master.vm.provider "vmware_fusion" do |v|
      v.vmx["memsize"]  = "#{managerRam}"
    end
    master.vm.provider :virtualbox do |v|
      v.name = master.vm.hostname.to_s
      v.customize ["modifyvm", :id, "--memory", "#{managerRam}"]
      file_to_disk = File.realpath( "." ).to_s + "/" + v.name + "_secondary_hdd.vdi"
      if ARGV[0] == "up" && ! File.exist?(file_to_disk)
        v.customize ['storagectl', :id, '--name', 'SATA', '--portcount', 2, '--hostiocache', 'on']
        v.customize ['createhd', '--filename', file_to_disk, '--format', 'VDI', '--size', "#{secondaryStorage * 1024}"]
        v.customize ['storageattach', :id, '--storagectl', 'SATA', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', file_to_disk]
      end
    end

    master.vm.provision :shell, :path => "provision_for_mount_disk.sh"
    master.vm.provision :shell, :inline => $hosts_data
    master.vm.provision :shell, :path => "provision_for_cdh_node.sh"
    master.vm.provision :shell, :path => "provision_for_cdh_master.sh"
  end

    # DataNodes
  nodeCount.times do |i|
    id = i+1
    config.vm.define "cdh-node#{id}" do |node|
      node.vm.network :private_network, ip: "#{privateSubnet}.#{privateStartingIp + id}", :netmask => "255.255.255.0", virtualbox__intnet: "cdhnetwork"
      node.vm.hostname = "cdh-node#{id}"
      node.vm.provider "vmware_fusion" do |v|
        v.vmx["memsize"]  = "#{nodeRam}"
      end
      node.vm.provider :virtualbox do |v|
        v.name = node.vm.hostname.to_s
        v.customize ["modifyvm", :id, "--memory", "#{nodeRam}"]
        file_to_disk = File.realpath( "." ).to_s + "/" + v.name + "_secondary_hdd.vdi"
        if ARGV[0] == "up" && ! File.exist?(file_to_disk)
          v.customize ['storagectl', :id, '--name', 'SATA', '--portcount', 2, '--hostiocache', 'on']
          v.customize ['createhd', '--filename', file_to_disk, '--format', 'VDI', '--size', "#{secondaryStorage * 1024}"]
          v.customize ['storageattach', :id, '--storagectl', 'SATA', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', file_to_disk]
        end
      end
      node.vm.provision :shell, :path => "provision_for_mount_disk.sh"
      node.vm.provision :shell, :inline => $hosts_data
      node.vm.provision :shell, :path => "provision_for_cdh_node.sh"
      node.vm.provision :shell, :path => "provision_for_cdh_datanode.sh"
     end
  end

end