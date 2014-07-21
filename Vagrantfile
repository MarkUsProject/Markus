# This Vagrantfile is for development use only.
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "markusproject/debian"
  # Access the server running on port 3000 on the host on port 42069.
  config.vm.network "forwarded_port", guest: 3000, host: 42069

  config.vm.provider "virtualbox" do |vb|
    # Uncomment the following line if you want a GUI.
    # vb.gui = true
    vb.name = "markus"
  end
end
