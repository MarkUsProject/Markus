# This Vagrantfile is for development use only.
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "markusproject/ubuntu"
  
  # Allow instance to see project folder.
  # Warning: This may cause problems with your Vagrant box!
  #          Enable at your own risk.
  # config.vm.synced_folder ".", "/home/vagrant/Markus"

  # Access the server running on port 3000 on the host on port 3000.
  config.vm.network "forwarded_port", guest: 3000, host: 3000

  config.vm.provider "virtualbox" do |vb|
    # Uncomment the following line if you want a GUI.
    # vb.gui = true
    vb.name = "markus"
    vb.memory = 2048
  end
end
