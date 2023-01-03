require 'archive_tools/course_archiver'

describe ArchiveTools::CourseArchiver do
  include ArchiveTools::CourseArchiver
  let(:full_course) do
    course = create :course
    create :assignment_with_criteria_and_test_results, course: course
    create :assignment_with_criteria_and_results_and_tas, course: course
    create :assignment_with_criteria_and_results_with_remark, course: course
    create :assignment_with_deductive_annotations, course: course
    create :assignment_with_peer_review_and_groupings_results, course: course
    create :assignment_for_student_tests, course: course
    create :assignment_for_scanned_exam, course: course
    create :timed_assignment, course: course
    assignment = create :assignment, course: course
    create_list :starter_file_group_with_entries, 3, assignment: assignment
    create :key_pair, user: course.roles.first.user
    allow_any_instance_of(AutotestSetting).to receive(:register).and_return('someapikey')
    allow_any_instance_of(AutotestSetting).to receive(:get_schema).and_return('{}')
    autotest_settings = create :autotest_setting
    course.update!(autotest_setting_id: autotest_settings.id)
    course
  end
  let(:unzipped_archive) do
    archive_dir = Rails.root.join('tmp/unarchive-workspace')
    FileUtils.rm_rf archive_dir
    FileUtils.mkdir_p archive_dir
    Open3.capture2('tar', '-xzvf', archive_file.to_s, '-C', archive_dir.to_s)
    archive_dir
  end
  let(:archived_db_data) { Dir[unzipped_archive + '*/db/*.csv'] }
  let(:archived_structure_file) { Dir[unzipped_archive + '*/db/structure.sql'].first }
  let(:archived_file_loc) { Dir[unzipped_archive + '*/data'].first }
  let(:archived_file_data) { Dir[unzipped_archive + '*/data/*'] }
  let(:archived_courses_file) { Dir[unzipped_archive + '*/db/courses.csv'].first }
  let(:archived_course_id) { CSV.parse(File.read(archived_courses_file), headers: true).first['id'] }
  describe '.archive' do
    before { FileUtils.rm_f archive_file }
    subject { archive course_name }
    let(:course_name) { course.name }
    let(:archive_file) { Rails.root.join("tmp/archive-#{course.name}.tar.gz") }
    shared_examples 'archive course' do
      before { subject }
      it 'it creates an archive file' do
        expect(File.exist?(archive_file)).to be_truthy
      end
      it 'contains a copy of the structure.sql file' do
        expect(File.read(archived_structure_file)).to eq File.read(Rails.root + 'db/structure.sql')
      end
      it 'contains the correct course id' do
        expect(archived_course_id).to eq course.id.to_s
      end
      it 'contains the expected db files' do
        subject
        Rails.application.eager_load!
        files = ApplicationRecord.descendants
                                 .reject { |klass| ids_associated_to_course(course, klass).empty? }
                                 .map { |klass| "#{klass.table_name}.csv" }
                                 .uniq - ['key_pairs.csv']
        expect(archived_db_data.map { |f| File.basename(f) }).to contain_exactly(*files)
      end
      it 'contains the expected data files' do
        subject
        Rails.application.eager_load!
        allow(Settings).to receive(:file_storage).and_return Config::Options.new(default_root_path: archived_file_loc)
        files = ApplicationRecord.descendants
                                 .select { |klass| klass.method_defined? :_file_location }
                                 .map { |klass| klass.all.map { |r| r.course == course ? r._file_location : nil } }
                                 .flatten
                                 .compact
        expect(files.all? { |f| File.exist? f }).to be_truthy
      end
    end
    context 'a minimal course' do
      let(:course) { create :course }
      it_behaves_like 'archive course'
    end
    context 'a full course' do
      let(:course) { full_course }
      it_behaves_like 'archive course'
    end
    context 'when other courses exist' do
      let(:course) { create :course }
      let(:assignment) { create :assignment, course: create(:course) }
      before { assignment }
      it_behaves_like 'archive course'
      it 'does not contain the additional course data' do
        subject
        ids = CSV.parse(File.read(archived_courses_file), headers: true).map { |row| row['id'] }
        expect(ids).to contain_exactly(course.id.to_s)
      end
      it 'does not contain the additional course files' do
        subject
        allow(Settings).to receive(:file_storage).and_return Config::Options.new(default_root_path: archived_file_loc)
        expect(File.exist?(assignment._file_location)).to be_falsy
      end
    end
  end
  describe '.unarchive', use_transactional_fixtures: false do
    subject { unarchive archive_file.to_s, tmp_db_url: tmp_db_url }
    around(:each) do |example|
      tmp_file_storage = Rails.root.join('tmp/unarchive_file_storage')
      old_file_storage = Settings.file_storage
      FileUtils.rm_rf tmp_file_storage
      FileUtils.mkdir_p tmp_file_storage
      Settings.file_storage = Config::Options.new(default_root_path: tmp_file_storage)
      example.run
    ensure
      Settings.file_storage = old_file_storage
      FileUtils.rm_rf tmp_file_storage
    end
    let(:tmp_db_url) { nil }
    let(:archive_file) { Rails.root.join('spec/fixtures/files/unarchive/good_full.tar.gz') }
    shared_examples 'cleanup after' do
      let(:temporary_database_name) do
        original = self.method(:temporary_database)
        allow(self).to receive(:temporary_database) do |db_name, options, &block|
          original.call(db_name, **options, &block)
          return db_name
        end
        subject
      end
      it 'should clean up temporary databases' do
        db = temporary_database_name
        databases = ActiveRecord::Base.connection.execute('SELECT datname FROM pg_database').values.flatten
        expect(databases).not_to include(db)
      end
    end
    shared_examples 'unarchive course' do
      it 'should create a course' do
        expect { subject }.to change { Course.count }.from(0).to(1)
      end
      it 'should create all records' do
        original = self.method(:extract_archive)
        records = Hash.new { |h, k| h[k] = [] }
        allow(self).to receive(:extract_archive) do |archive_file, destination|
          original.call(archive_file, destination)
          Dir[destination.to_s + '/*/db/*.csv'].each do |file_name|
            CSV.parse(File.read(file_name), headers: true)&.each do |row|
              records[File.basename(file_name, '.csv')] << row['id']
            end
          end
        end
        subject
        actual_records = records.keys.index_with do |table|
          ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{table}").values.flatten.first
        end
        expect(actual_records).to eq(records.transform_values(&:count))
      end
      it 'should create all valid records' do
        subject
        expect(ApplicationRecord.descendants.map { |klass| klass.find_each.map(&:valid?) }.flatten.all?).to be_truthy
      end
    end
    shared_examples 'fail to unarchive a course' do
      it 'should not create a course' do
        expect { subject }.not_to(change { Course.count })
      end
      it 'should create no records' do
        subject
        expect(ApplicationRecord.descendants.map(&:count).all?(&:zero?)).to be_truthy
      end
    end
    context 'using a minimal archive file' do
      let(:archive_file) { Rails.root.join('spec/fixtures/files/unarchive/good_min.tar.gz') }
      it_behaves_like 'unarchive course'
      it_behaves_like 'cleanup after'
    end
    context 'using a full valid archive file' do
      it_behaves_like 'unarchive course'
      it_behaves_like 'cleanup after'
    end
    context 'using an archive file with missing data' do
      before do
        allow(self).to receive(:extract_archive) do |archive_file, destination|
          FileUtils.rm_rf destination
          FileUtils.mkdir_p destination
          Open3.capture2('tar', '-xzvf', archive_file, '-C', destination.to_s, '--exclude', exclude_pattern)
        end
      end
      context 'missing db data' do
        let(:exclude_pattern) { '*/db/assessments.csv' }
        it_behaves_like 'cleanup after'
        it_behaves_like 'fail to unarchive a course'
      end
      context 'missing file data' do
        let(:exclude_pattern) { '*/data/autotest/1772' } # there is an assignment with id = 1772 in the archive
        it_behaves_like 'cleanup after'
        it_behaves_like 'fail to unarchive a course'
      end
    end
  end
  describe '.remove_db_and_data' do
    subject { remove_db_and_data course_name }
    let(:course) { create :course }
    let(:course_name) { course.name }
    shared_examples 'remove a course' do
      before { subject }
      it 'should delete the course' do
        expect { course.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end
      it 'should keep all existing records valid' do
        # if some records were stranded they would no longer be valid
        expect(ApplicationRecord.descendants.map { |klass| klass.find_each.map(&:valid?) }.flatten.all?).to be_truthy
      end
    end
    context 'a minimal course' do
      it_behaves_like 'remove a course'
    end
    context 'a full course' do
      let(:course) { full_course }
      it_behaves_like 'remove a course'
      it 'should not remove records not associated with the course' do
        course
        expect { subject }.not_to(change { User.count })
      end
    end
    context 'when other courses exist' do
      let(:assignment) { create :assignment, course: create(:course) }
      before { assignment }
      it_behaves_like 'remove a course'
      it 'should not remove the other course or associated records' do
        expect { assignment.course.reload }.not_to raise_exception
      end
    end
  end
end
