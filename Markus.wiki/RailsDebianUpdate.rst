================================================================================
Update rails on Ubuntu >= 8.10 (and other Debian based systems)
================================================================================

Problem
================================================================================

In order to install rails >=2.2 you need to have RubyGems 1.3.7. But::

  #> gem -v
  1.2.0
  #> sudo gem update --system
  ERROR:  While executing gem ... (RuntimeError)
          gem update --system is disabled on Debian. RubyGems can be updated \
          using the official Debian repositories by aptitude or apt-get

Solution
================================================================================

Here is the solution::

  #> wget http://rubyforge.org/frs/download.php/70696/rubygems-1.3.7.tgz
  #> tar -xzf rubygems-1.3.7.tgz
  #> cd rubygems-1.3.7
  #> sudo ruby setup.rb
  #> sudo mv /usr/bin/gem /usr/bin/gem.old
  #> sudo ln -s /usr/bin/gem1.8 /usr/bin/gem
  #> gem -v 1.3.7

Now you are ready to install rails. You may use our deployment instructions to
do so. Developers please see our development setup instructions



