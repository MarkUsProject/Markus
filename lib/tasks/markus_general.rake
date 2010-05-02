namespace :markus do
  
  namespace :dev do
    RAILS_ENV="development"
    desc "Resets a MarkUs installation. Useful for developers. This is just a rake repos:drop && rake db:reset && rake db:populate"
    task(:reset => :environment) do
      Rake::Task['repos:drop'].invoke   # drop repositories
      Rake::Task['db:reset'].invoke     # reset the DB
      sleep(2) # need to sleep a little, otherwise the reset doesn't seem to work
      Rake::Task['db:populate'].invoke  # repopulate DB
      puts("Resetting development environment of MarkUs finished!")
    end
  end
 
end
