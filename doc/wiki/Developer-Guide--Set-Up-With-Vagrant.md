## Downloading and Installing

If you want to get started on working on MarkUs quickly and painlessly, this is the way to do it.

1. Install [VirtualBox](https://www.virtualbox.org/) and [Vagrant](http://www.vagrantup.com/)
2. Clone the Markus repo from GitHub by following the instructions in [Setting up Git and MarkUs](./Developer-Guide--Setting-up-Git).  (This is a document you will want to read very carefully and may come back to.)
3. `cd` to the repo (make sure you’re in the right directory - it should contain the Vagrantfile)
4. `vagrant up`

This will download a fairly large (3GB) Debian box from the internet, so go [take a walk](http://news.stanford.edu/news/2014/april/walking-vs-sitting-042414.html) or something. This box has GNOME, PostgreSQL, git, and all of MarkUs’s other dependencies installed. When the download is complete, VirtualBox will run the box in headless mode.

**NOTE:** If, for some reason, it fails and complains about SSH, you most likely have timed out. Check your internet connection attempt to limit network activity to `vagrant up`.



## Connecting to your box

Next, run `vagrant ssh` to connect to the virtual machine. (If it asks you for a password for vagrant, the password is "vagrant".)  To avoid having to enter a password each time, and to use RubyMine, [set up](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2) a public private key pair, and copy the public key to `~/.ssh/authorized_keys` on the vagrant vm. Then open the VagrantFile on your local machine and add `config.ssh.private_key_path = "ABSOLUTE_PATH"` directly under `config.vm.box = markusproject/ubuntu`.  ABSOLUTE_PATH is the path to your private key (E.g. `$HOME/.ssh/id_rsa`).

Note: On Windows you may find that you need to put the private key in the same directory as the Vagrantfile.

**NOTE:** It is possible to set up the virtual machine to share folders with the host machine, but in our experience, this is too slow to be a good work environment, and sometimes doesn't work at all.  If you do want to enable shared folders, you can check out that [vagrant documentation](http://docs.vagrantup.com/v2/synced-folders/).  We have found it more effective to work with files locally using RubyMine and deploy/upload to the vagrant box when you want to try things out.

Finally, run `markus` from the project directory.

You should now be able to access the site from your host machine's browser at `http://0.0.0.0:3000/csc108`.

The default admin user is `a` with any non-empty password. Look at `db/seeds.rb` for other users.

If you are using RubyMine then you should jump down to the set up instructions for RubyMine below before proceeding to the next step.


## Using RubyMine

1. Install [RubyMine](https://www.jetbrains.com/ruby/), and then run it.
2. When RubyMine runs, select `Open`, or `File > Open`, and navigate to your cloned MarkUs folder on your local machine.

    **NOTE**: RubyMine will tell you that there are missing gems to be installed, it is okay to ignore this.
3. Open `File > Settings` (on Windows) or `RubyMine > Preferences` (on OSX) where we will configure some different settings.

    1) In `Tools > Vagrant`, set the *Instance folder* to your Markus directory on your local machine and leave the *Provider* as "Default".

    2) Go to `Languages & Frameworks > Ruby SDK and Gems`, and click add symbol (plus sign) and select "New remote...". There are two ways to set up RubyMine to use the Ruby installed on the Vagrant machine.

        a) Select the Vagrant radio button, set the instance folder to the root MarkUs folder where the Vagrantfile is.
           Confirm the connection works by clicking on the Host URL.

        b) If (a) does not work, then select the SSH Credentials radio button and enter the following:

            ```
            Host: localhost (**NOTE:** Windows may fail if you use 127.0.0.1, try using 'localhost' first before 127.0.0.1)
            Port: 2222
            User name: vagrant
            Auth type: Password
            Password: vagrant, the password checkbox is selected
            Ruby interpreter path: /usr/bin/ruby
            ```

        Now return to the Ruby SDK and Gems window and make sure the ruby you selected is installed.

    3) Click `OK` to save your settings and close the window.

3. You can open an ssh session to the vagrant virtual machine directly in RubyMine from `Tools > Start SSH Session`. You need to make sure that you have installed a public key on the vagrant machine so that you don't need a password (or passphrase) to ssh into the vagrant VM.

At this point, you may need to restart RubyMine before making the next step work. There also is an option to do SSH through RubyMine and start/pause/kill Vagrant if you have not done so before starting RubyMine. These commands can be found under `Tools > Vagrant`. You may need the Vagrant machine to be running for the next step:

4. In RubyMine, select `Tools > Deployment > Configuration`, and click the + in the top left to add a new server. After giving it a name, under `Connection` use the following settings:

    ```
    Type: SFTP
    Host: localhost
    Port: 2222
    User name: vagrant
    Authentication: password
    Password: vagrant
    Root path: /home/vagrant
    ```

5. In the same window, under `Mappings` set:

    ```
    Local path: [path to your local Markus repo]
    Deployment path on server: /Markus
    ```

6. In the same window under `Excluded Paths`, add the following sets of paths.

    **Deployment paths**:
    - /Markus/.bundle
    - /Markus/.byebug_history
    - /Markus/config/database.yml
    - /Markus/data/dev
    - /Markus/log
    - /Markus/node_modules
    - /Markus/public/javascripts
    - /Markus/public/packs
    - /Markus/public/packs-test
    - /Markus/vendor/bundle
    - /Markus/lib/scanner/venv

    **Local paths** (MARKUS_ROOT is the location of your MarkUs repo):
    - MARKUS_ROOT/.vagrant
    - MARKUS_ROOT/config/dummy_validate.sh

7. Click `OK` to save your changes and close the window.

8. Select `Tools > Options`, and set:

    - "Delete target items when source ones do not exist..." should be **checked**.
    - "Upload changed files automatically to the default server..." should be **On explicit save action**.
    - "Skip external changes" should be **NOT checked**.

    Click OK to save your changes.

9. To test out this configuration, first right-click on the Markus folder in the "Project" pane, and select `Deployment > Upload to vagrant`. This should take a bit of time, as your files are copied from your local machine to the virtual machine.

    Whenever you make changes to the files, you can do an explicit save action and *all* of your changes will be uploaded to the virtual machine.

Congratulations, you're all done and ready to get started working on MarkUs!
