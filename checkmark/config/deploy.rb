set :application, "checkmark"
set :repository,  "https://stanley.cdf.toronto.edu/svn/csc49x/olm_rails/trunk/checkmark/"

set :application, "checkmark"
set :deploy_to, "/data/c494h01/checkmark"

set :keep_releases, 4

role :app, "dbsrv3.cdf.utoronto.ca"
role :web, "dbsrv3.cdf.utoronto.ca"
role :db,  "dbsrv3.cdf.utoronto.ca", :primary => true

set :runner, 'mongrel'
set :mongrel_conf, "#{current_path}/config/mongrel_cluster.yml"

set :user, 'g4alouis' # going to have to do something about this...
set :use_sudo, false
ssh_options[:port] = 22
ssh_options[:username] = 'g4alouis'


task :after_update_code, :roles => :app do 
  copy_database_config
  set_group_permissions
end

# mongrel commands
namespace :deploy do
  desc "The spinner task is used by :cold_deploy to start the application up"
  task :spinner, :roles => :app do
    run "cd #{release_path}/ && mongrel_rails cluster::start"
  end

  desc "Restart the mongrel cluster"
  task :restart, :roles => :app do
    run "cd #{release_path}/ && mongrel_rails cluster::restart"
  end
  
  desc "Restart the mongrel cluster"
  task :stop, :roles => :app do
    run "cd #{release_path}/ && mongrel_rails cluster::stop"
  end  
end

# copy database config from shared to release
def copy_database_config
  db_config = "#{shared_path}/config/database.yml"
  run "cp -f #{db_config} #{release_path}/config/database.yml"
end

# give group the right permissions on the files in 'current'
def set_group_permissions
  # we use a weird chmod option to give the permissions
  # of the user to the group on all files/dirs
  run "chmod -R g=u #{release_path}/*"
end