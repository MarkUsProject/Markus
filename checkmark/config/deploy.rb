set :application, "checkmark"
set :repository,  "https://stanley.cdf.toronto.edu/svn/csc49x/olm_rails/trunk/checkmark/"

set :domain, 'alfred'
set :application, "checkmark"
set :deploy_to, "/data/c494h01/checkmark"

set :keep_releases, 4

role :app, "dbsrv3.cdf.utoronto.ca"
role :web, "dbsrv3.cdf.utoronto.ca"
role :db,  "dbsrv3.cdf.utoronto.ca", :primary => true

set :runner, 'mongrel'
set :mongrel_conf, "#{current_path}/config/mongrel_cluster.yml"

set :user, 'g4alouis'
set :use_sudo, false

ssh_options[:port] = 22
ssh_options[:username] = 'g4alouis'


# launch mongrel 
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