namespace :test do
  desc "Run the selenium tests in test/selenium and start/stop the selenium server"
  task(:selenium) do
    if RAILS_ENV != "test"
      $stderr.puts "Need RAILS_ENV=test to run this task"
      exit(1)
    end
    #Load the fixtures into the test database
    Rake::Task["db:fixtures:load"].invoke
  
    #Start the selenium-server
    Rake::Task["selenium:rc:start"].execute
  
    begin
      Rake::Task["test:selenium_with_server_started"].invoke 
    ensure
    #Stop the selenium-server
      Rake::Task["selenium:rc:stop"].execute
    end
  end
  
  Rake::TestTask.new(:selenium_with_server_started) do |t|
    t.libs << "test"
    t.pattern = 'test/selenium/**/*_test.rb'
    t.verbose = true
  end
    
  Rake::Task['test:selenium_with_server_started'].comment = "Run the selenium tests in test/selenium without starting a selenium server"
end
