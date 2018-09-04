# clean up existing repos first
FileUtils.rm_rf(Dir.glob('data/dev/repos/*'))
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
Rake::Task['db:autotest'].invoke
