Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"
  config.vm.hostname = "llm-lab"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "llm-lab"
    vb.memory = 8192
    vb.cpus = 4
  end

  config.vm.network "private_network", ip: "192.168.56.30"

  config.vm.synced_folder ".", "/vagrant"

  config.vm.provision "shell", path: "scripts/setup.sh"
end
