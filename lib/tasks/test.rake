require 'rake/testtask'
require 'rails/test_unit/sub_test_task'

namespace :test do
  task run: ['test:libs']

  Rake::TestTask.new('lib') do |t|
    t.libs    = ['test']
    t.pattern = 'lib/**/*_test.rb'
  end
  task libs: 'test:prepare'

end

