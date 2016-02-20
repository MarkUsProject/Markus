# To create resque workers
require 'resque/tasks'
task 'resque:setup' => :environment