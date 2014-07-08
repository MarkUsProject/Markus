VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "markusproject/debian"
  config.vm.network "forwarded_port", guest: 3000, host: 42069

  config.vm.provider "virtualbox" do |vb|
    # Don't boot with headless mode
    # vb.gui = true
    vb.name = "markus"
  end
end
