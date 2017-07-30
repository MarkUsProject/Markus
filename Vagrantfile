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
  # Make sure to get all the puppet modules by running
  #    git submodule update --init --recursive
  config.vm.define "pupkus", autostart: false do |pupkus|
    pupkus.vm.box = "puppetlabs/debian-8.2-64-puppet"

    pupkus.vm.network :private_network, ip: '192.168.50.50'
    pupkus.vm.synced_folder '.', '/vagrant', nfs: true, mount_options: ['rw', 'vers=3', 'tcp', 'fsc' ,'actimeo=1']
    pupkus.vm.network "forwarded_port", guest: 3000, host: 3000

    # Configure VirtualBox
    pupkus.vm.provider "virtualbox" do |vb|
      vb.name = "markus-puppet"
      vb.memory = 2048
      vb.cpus = 4
      vb.customize ["modifyvm", :id, "--ioapic", "on"]
    end

    # Provision the server using puppet.
    pupkus.vm.provision "puppet" do |puppet|
      puppet.environment_path = "puppet/environments"
      puppet.module_path = "puppet/modules"
      puppet.environment = "testenv"
    end
  end
end
