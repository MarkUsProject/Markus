require 'rubygems'
require 'selenium/rake/tasks' if ::Rails.env == "test" # use selenium rc rake tasks that are bundled with the selenium-client gem

namespace :selenium do
  if ::Rails.env == "test"
    SELENIUM_RC_JAR = 'vendor/selenium-rc/selenium-server-1.0.1.jar'

    # Start selenium server task
    Selenium::Rake::RemoteControlStartTask.new(:'rc:start') do |rc|
      rc.port = 4444
      rc.timeout_in_seconds = 3 * 60
      rc.background = true
      rc.wait_until_up_and_running = true
      rc.jar_file = SELENIUM_RC_JAR
    end

    # Stop selenium server task
    Selenium::Rake::RemoteControlStopTask.new(:'rc:stop') do |rc|
      rc.host = "localhost"
      rc.port = 4444
      rc.timeout_in_seconds = 3 * 60
    end
  end

  # Restart selenium server task
  desc "Restart Selenium Remote Control"
  task :'rc:restart' do
    Rake::Task[:"selenium:rc:stop"].execute [] rescue nil
    Rake::Task[:"selenium:rc:start"].execute []
  end
end
