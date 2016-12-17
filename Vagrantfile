# This Vagrantfile is for development use only.
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # MarkUs from a snapshot image.
  config.vm.define "default", primary: true do |default|
    default.vm.box = "markusproject/ubuntu"

    # Set this to your private key if you're having trouble
    # ssh-ing into Vagrant (it's requiring a password)
    # default.ssh.private_key_path = "/home/.ssh/id_rsa"

    # Allow instance to see project folder.
    # Warning: This may cause problems with your Vagrant box!
    #          Enable at your own risk.
    # default.vm.synced_folder ".", "/home/vagrant/Markus"

    # Access the server running on port 3000 on the host on port 3000.
    default.vm.network "forwarded_port", guest: 3000, host: 3000

    default.vm.provider "virtualbox" do |vb|
      # Uncomment the following line if you want a GUI.
      # vb.gui = true
      vb.name = "markus"
      vb.memory = 2048
    end
  end

  # MarkUs provisioned by puppet using the current directory as document root.
  config.vm.define "pupkus", autostart: false do |pupkus|
    pupkus.vm.box = "puppetlabs/debian-8.2-64-puppet"

    # Configure VirtualBox
    pupkus.vm.provider "virtualbox" do |vb|
      vb.name = "markus-puppet"
      vb.memory = 2048
    end

    # Provision the server using puppet.
    pupkus.vm.provision "puppet" do |puppet|
      puppet.environment_path = "puppet/environments"
      puppet.environment = "testenv"
    end
  end
end
