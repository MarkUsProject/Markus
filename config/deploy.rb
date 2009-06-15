# Necessary to run on Site5
set :use_sudo, false
set :group_writable, false

# Less releases, less space wasted
set :keep_releases, 2

# thanks to http://www.rubyrobot.org/article/deploying-rails-20-to-mongrel-with-capistrano-21
set :runner, nil

set :application, "markus_cap1"
set :user, "markuspr"
set :repository, "https://stanley.cdf.toronto.edu/svn/csc49x/olm_rails/trunk/"
#
set :deploy_to, "/home/#{user}/markus-apps/#{application}"
default_run_options[:pty] = true

role :app, "satyrs.site5.com"
role :web, "satyrs.site5.com"
role :db,  "satyrs.site5.com", :primary => true

desc "Restart the web server. Overrides the default task for Site5 use"
deploy.task :restart, :roles => :app do
  run "cd /home/#{user}; rm -rf public_html; ln -s #{current_path}/public ./public_html"
  run "skill -9 -u #{user} -c dispatch.fcgi"
end

# set up config files
after "deploy:update_code", :configure_app
desc "Copy database.yml, environment.rb into the current release path"
task :configure_app, :roles => :app do
  db_config = "/home/#{user}/markus-apps/app_config/database.yml"
  env_config = "/home/#{user}/markus-apps/app_config/environment.rb"
  run "cp #{db_config} #{release_path}/config/database.yml"
  run "cp #{env_config} #{release_path}/config/environment.rb"
end