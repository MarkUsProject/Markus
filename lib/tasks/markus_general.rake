namespace :markus do
  
  desc "Resets a MarkUs installation. Useful for developers. This is just a rake repos:drop && rake db:reset && rake db:seed"
  task(:reset => :environment) do
    if ENV['environment'].nil?
      ::Rails.env = 'development'
      puts("Default environment is development, run the task with environment='development/production/test' to specify environment.")
    else
      ::Rails.env = ENV['environment']
    end
    Rake::Task['repos:drop'].invoke   # drop repositories
    Rake::Task['db:reset'].invoke     # reset the DB
    sleep(2) # need to sleep a little, otherwise the reset doesn't seem to work
    Rake::Task['db:seed'].invoke  # repopulate DB
    puts("Resetting development environment of MarkUs finished!")
  end
 
end
