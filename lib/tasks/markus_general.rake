namespace :markus do
  
  namespace :dev do
    RAILS_ENV="development"
    desc "Resets a MarkUs installation. Useful for developers. This is just a rake repos:drop && rake db:reset && rake db:populate"
    task(:reset => [:environment, :"repos:drop", :"db:reset", :"db:populate"]) do
      print("Resetting development environment of MarkUs...")
      # nothing to do here
      puts(" done!")
    end
  end
 
end
