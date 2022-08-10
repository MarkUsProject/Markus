# clean up existing repos first
if Dir.exist?(Repository::ROOT_DIR)
  FileUtils.rm_rf(Dir.glob(File.join(Repository::ROOT_DIR, '*')))
else
  FileUtils.mkdir_p(Repository::ROOT_DIR)
end

FileUtils.mkdir_p('tmp')

# run tasks
Rake::Task['db:courses'].invoke
Rake::Task['db:admin'].invoke
Rake::Task['db:instructor'].invoke
Rake::Task['db:tas'].invoke
Rake::Task['db:student_users'].invoke
Rake::Task['db:students'].invoke
Rake::Task['db:assignments'].invoke
Rake::Task['db:grade_entry_forms'].invoke
Rake::Task['db:groups'].invoke
Rake::Task['db:rubric'].invoke
Rake::Task['db:marks'].invoke
Rake::Task['db:remarks'].invoke
Rake::Task['db:peer_reviews'].invoke
Rake::Task['db:scanned_exam'].invoke
Rake::Task['db:marking_scheme'].invoke
