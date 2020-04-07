# clean up existing repos first
if Dir.exists?(Rails.configuration.x.repository.storage)
  FileUtils.rm_rf(Dir.glob(File.join(Rails.configuration.x.repository.storage, '*')))
else
  FileUtils.mkdir_p(Rails.configuration.x.repository.storage)
end

FileUtils.mkdir_p('tmp')


# run tasks
Rake::Task['db:admin'].invoke
Rake::Task['db:tas'].invoke
Rake::Task['db:test_servers'].invoke
Rake::Task['db:users'].invoke
Rake::Task['db:assignments'].invoke
Rake::Task['db:grade_entry_forms'].invoke
Rake::Task['db:groups'].invoke
Rake::Task['db:rubric'].invoke
Rake::Task['db:marks'].invoke
Rake::Task['db:remarks'].invoke
Rake::Task['db:peer_reviews'].invoke
Rake::Task['db:scanned_exam'].invoke
Rake::Task['db:marking_scheme'].invoke
