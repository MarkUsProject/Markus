# To create resque workers
require 'resque/tasks'
Resque.logger.level = Logger::DEBUG
task 'resque:setup' => :environment
