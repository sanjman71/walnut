First initialize the EC2 machine:

cap production machine:initial_setup
cap production machine:configure
cap production machine:install_dev_tools

Now you need to connect the MySQL and Sphinx EBS volumes:
cap production mysql:ebs
cap production sphinx:ebs

Setup the deployment:
cap production deploy:setup

As part of this step, MySQL was started. Create the database, assuming it isn't already on the ebs volume:
cap production mysql:create_database
cap production mysql:create_db_user
cap production mysql:grant_user_db_rights

cap production deploy:cold

Next time, to update and restart:
cap production deploy

Need to configure the production sphinx configuration file from templates.
Need to create the production sphinx index directory


Notes::
Need to chown the mysql data directory to mysql:root
Need to create and chown the tmp dir /mnt/tmp/mysql
We should run /usr/bin/mysql_secure_installation
From the MySQL mysql_install_database output:

  Alternatively you can run:
  /usr/bin/mysql_secure_installation

  which will also give you the option of removing the test
  databases and anonymous user created by default.  This is
  strongly recommended for production servers.

  See the manual for more instructions.

  You can start the MySQL daemon with:
  cd /usr ; /usr/bin/mysqld_safe &

  You can test the MySQL daemon with mysql-test-run.pl
  cd mysql-test ; perl mysql-test-run.pl
  
Need to support a list of packages to install using aptitude, as I have done for gems. See libcurl-dev for example.

Fix 'god start nginx' - god isn't found.

Copy the nginx configuration files - nginx.conf and www.walnutplaces.com

Need an nginx init.d script file.

Uninstalled rack 1.0.0, replaced with rack 0.9.1 - startup failure.
  undefined method `new' for "Rack::Lock":String (NoMethodError)

Switched to regular /usr/bin/ruby
Need mkmf to do anything useful. Basic Ubuntu requires this additional apt
286  sudo apt-get install ruby1.8-dev

As expected, using this ruby:
install rubygems
install rails
289  sudo gem install rails -v 2.3.2

install all gems

Had to install fastthread and mysql gems by hand

Then run 
291  sudo /usr/bin/gem install passenger --no-rdoc --no-ri
305  sudo passenger-install-nginx-module

