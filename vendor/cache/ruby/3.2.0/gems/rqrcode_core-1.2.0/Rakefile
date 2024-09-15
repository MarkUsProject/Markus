begin
  require "rake/testtask"
  require "standard/rake"

  Rake::TestTask.new(:test) do |t|
    t.libs << "test"
    t.libs << "lib"
    t.test_files = FileList["test/**/*_test.rb"]
  end

  task default: [:test, "standard:fix"]

  desc "Run a simple benchmark (x1000)"
  task :benchmark do
    ruby "test/benchmark.rb"
  end
rescue LoadError
  # no standard/rspec available
end
