# rubocop:disable Rails/RakeEnvironment
namespace :coverage do
  task :clean do
    rm_f 'test/coverage'
    rm_f 'test/coverage.data'
    ENV['COVERAGE'] = 'true'
  end

  desc 'Measures unit test coverage'
  task units: :clean do
    Rake::Task['test:units'].execute
  end

  desc 'Measures functional test coverage'
  task functionals: :clean do
    Rake::Task['test:functionals'].execute
  end

  desc 'Measures lib test coverage'
  task lib: :clean do
    Rake::Task['test:lib'].execute
  end

  desc 'All test coverage'
  task all: :clean do
    Rake::Task['test'].execute
  end
end

task :coverage do
  Rake::Task['coverage:all'].invoke
end
# rubocop:enable Rails/RakeEnvironment
