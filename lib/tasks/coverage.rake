namespace :coverage do

  task :clean do
    rm_f "test/coverage"
    rm_f "test/coverage.data"
    Rcov = "RAILS_ENV=test rcov --rails --output test/coverage --aggregate test/coverage.data -I'lib:test' \
                   --text-summary -x 'bundler/*,gems/*'" unless RUBY_VERSION > '1.9'
    Rcov = "RAILS_ENV=test simplecov --rails  --output test/coverage --aggregate test/coverage.data -I'lib:test' \
                   --text-summary -x 'bundler/*,gems/*'" if RUBY_VERSION > '1.9'
  end

  desc 'Measures unit test coverage'
  task :units => :clean do
    system("#{Rcov} --html `find test/unit/ -name '*_test.rb'`")
  end

  desc 'Measures functional test coverage'
  task :functionals => :clean do
    system("#{Rcov} --html `find test/functional/ -name '*_test.rb'`")
  end

  desc 'Measures lib test coverage'
  task :lib => :clean do
    system("#{Rcov} --html `find lib/repo/test/ -name '*_test.rb'`")
  end

  desc 'All test coverage'
  task :all => :clean do
    system("#{Rcov} --html `find test/ lib/repo/test/ -name '*_test.rb'`")
  end

end

task :coverage do
  Rake::Task["coverage:all"].invoke
end
