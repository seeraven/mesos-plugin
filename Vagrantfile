# -*- mode: ruby -*-
# vi: set ft=ruby :


# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  if Vagrant.has_plugin?("vagrant-proxyconf")
    puts "found proxyconf plugin!"
    if ENV["http_proxy"]
      puts "http_proxy:  " + ENV["http_proxy"]
      config.proxy.http     = ENV["http_proxy"]
    end
    if ENV["https_proxy"]
      puts "https_proxy: " + ENV["https_proxy"]
      config.proxy.https    = ENV["https_proxy"]
    end
    if ENV["no_proxy"]
      puts "no_proxy:    " + ENV["no_proxy"]
      config.proxy.no_proxy = ENV["no_proxy"]
    end
  end

  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "ubuntu/xenial64"

  # Forward mesos ports.
  config.vm.network "forwarded_port", guest: 5050, host: 8050
  config.vm.network "forwarded_port", guest: 5051, host: 8051

  # Forward jenkins port.
  config.vm.network "forwarded_port", guest: 8080, host: 8090

  # Provision the system.
  config.vm.provision "shell", path: "vagrant/provisioning.sh"

  config.vm.provider :virtualbox do |vb|
     # Use VBoxManage to customize the VM. For example to change memory:
     vb.customize ["modifyvm", :id, "--memory", "2048"]
     vb.customize ["modifyvm", :id, "--cpus", "2"]
  end

end
