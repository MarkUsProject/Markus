# This Vagrantfile is for development use only.
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "bento/ubuntu-16.04"
  config.vm.define :markus_box

  # Set this to your private key if you're having trouble
  # ssh-ing into Vagrant (it's requiring a password)
  # config.ssh.private_key_path = "/home/.ssh/id_rsa"
  config.ssh.password = "vagrant"

  # Allow instance to see project folder.
  # Warning: This may cause problems with your Vagrant box!
  #          Enable at your own risk.
  config.vm.synced_folder ".", "/home/vagrant/Markus", disabled: true

  # Access the server running on port 3000 on the host on port 3000.
  config.vm.network "forwarded_port", guest: 3000, host: 3000

  config.vm.provision "install-markus", type: "shell" do |s|
    s.path = "script/install-markus.sh"
    s.privileged = false
  end

  config.vm.provision "install-markus-autotesting", type: "shell", run: "never" do |s|
    s.path = "script/install-markus-autotesting.sh"
    s.privileged = false
  end

  config.vm.provision "install-svn", type: "shell", run: "never" do |s|
    s.path = "script/install-svn.sh"
    s.privileged = false
  end

  config.vm.provider "virtualbox" do |vb|
    # Uncomment the following line if you want a GUI.
    # vb.gui = true
    vb.name = "markus"
    vb.memory = 2048
  end

  config.vm.post_up_message =
    <<~HEREDOC
      markus_box is running! Test your installation by running

        $ vagrant ssh -c markus

      Then visit localhost:3000, and you should see the MarkUs login screen.
      Login as an admin with username 'a' and any non-empty password.

      Then to complete the installation, run the following provisioning commands:

        $ vagrant provision --provision-with=install-markus-autotesting
        $ vagrant provision --provision-with=install-svn
    HEREDOC
end
