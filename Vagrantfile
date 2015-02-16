# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "hashicorp/precise32"
  config.vm.provision :shell, path: "provision/bootstrap.sh"

  config.vm.provider "virtualbox" do |v|
  	v.name = "circuit-analysis"
  end
end
