# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'yaml'

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"
  config.vm.box_check_update = true

  config.vm.network "forwarded_port", guest: 80, host: 8080 # Colab under nginx
  config.vm.network "forwarded_port", guest: 8080, host: 8081 # Discourse
  config.vm.network "forwarded_port", guest: 9000, host: 8082 # Wikilegis
  config.vm.network "forwarded_port", guest: 7000, host: 8083 # Audiencias

  directory_name = "../edem_applications"
  Dir.mkdir(directory_name) unless File.exists?(directory_name)

  config.vm.synced_folder directory_name, "/edem_applications"

  env = ENV.fetch('EDEM_ENV', 'local')
  if File.exist?("config/#{env}/ips.yaml")
    ips = YAML.load_file("config/#{env}/ips.yaml")
  else
    ips = nil
  end

  config.vm.define "edemocracia" do |edemocracia|
    edemocracia.vm.provider "virtualbox" do |vb, override|
      override.vm.network "private_network", ip: ips["edemocracia"]
      vb.memory = "3072"
    end
  end
end
