exit unless Rails.env.development?

# clean up existing files first
FileUtils.rm_rf(Repository.root_dir)
FileUtils.rm_rf(Assignment.starter_files_dir)
FileUtils.rm_rf(TestRun.settings_files_dir)

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
