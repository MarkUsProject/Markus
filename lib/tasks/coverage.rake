namespace :coverage do

  task :clean do
    rm_f "test/coverage"
    rm_f "test/coverage.data"
    Rcov = "RAILS_ENV=test rcov --rails --output test/coverage --aggregate test/coverage.data -Ilib \
                   --text-summary -x 'bundler/*,gems/*'" unless RUBY_VERSION > '1.9'
    Rcov = "RAILS_ENV=test simplecov --rails  --output test/coverage --aggregate test/coverage.data -Ilib \
                   --text-summary -x 'bundler/*,gems/*'" if RUBY_VERSION > '1.9'
  end

  def display_coverage
    system("sensible-browser test/coverage/index.html")
  end

  desc 'Measures unit test coverage'
  task :units => :clean do
    system("#{Rcov} --html test/unit/*_test.rb \
           test/unit/*/*_test.rb")
    display_coverage
  end

  desc 'Measures functional test coverage'
  task :functionals => :clean do
    system("#{Rcov} --html test/functional/*_test.rb \
           test/functional/*/*_test.rb")
    display_coverage
  end

  desc 'Measures lib test coverage'
  task :lib => :clean do
    system("#{Rcov} --html lib/repo/test/*_test.rb")
    display_coverage
  end

  desc 'All test coverage'
  task :all => :clean do
    system("#{Rcov} --html test/unit/*_test.rb test/unit/*/*_test.rb \
           test/functional/*_test.rb test/functional/*/*_test.rb \
           test/lib/repo/test/*_test.rb")
    display_coverage
  end

end

task :coverage do
  Rake::Task["coverage:all"].invoke
end
