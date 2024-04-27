# This Vagrantfile is for development use only.
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "bento/ubuntu-18.04"
  config.vm.define :markus_box

  config.vm.provider "virtualbox" do |vb|
    # Uncomment the following line if you want a GUI.
    # vb.gui = true
    vb.name = "markus"
    vb.memory = 2048

    # Sync time every 5 seconds so code reloads properly
    vb.customize ["guestproperty", "set", :id, "--timesync-threshold", 5000]
  end

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
  # Webpack-dev-server listens on port 3035.
  config.vm.network "forwarded_port", guest: 3035, host: 3035
  # rq-dashboard
  config.vm.network "forwarded_port", guest: 9181, host: 9181

  # The autotesting server must be running when MarkUs populates the seed database
  config.vm.provision "install-markus-autotesting", type: "shell" do |s|
    s.path = "script/install-markus-autotesting.sh"
    s.privileged = false
    s.args = "~/markus-autotesting"
  end

  config.vm.provision "install-markus", type: "shell" do |s|
    s.path = "script/install-markus.sh"
    s.privileged = false
    s.args = "~/Markus"
  end

  config.vm.provision "start-autotest-workers", type: "shell", run: "always" do |s|
    s.path = "script/start-autotest-workers.sh"
    s.privileged = false
    s.args = "~/markus-autotesting"
  end

  config.vm.post_up_message =
    <<~HEREDOC
      markus_box is running! Test your installation by running

        $ vagrant ssh -c markus

      Then visit localhost:3000/csc108, and you should see the MarkUs login screen.
      Login as an instructor with username 'a' and any non-empty password.
    HEREDOC
end
