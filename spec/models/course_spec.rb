describe Course do
  let(:course) { create(:course) }

  context 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { expect(course).to validate_uniqueness_of(:name) }
    it { is_expected.not_to allow_value('Mike Ooh').for(:name) }
    it { is_expected.not_to allow_value('A!a.sa').for(:name) }
    it { is_expected.to allow_value('Ads_-hb').for(:name) }
    it { is_expected.to allow_value('-22125-k1lj42_').for(:name) }
    it { is_expected.to allow_value('CSC108 2021 Fall').for(:display_name) }
    it { is_expected.to allow_value('CSC108, 2021 Fall').for(:display_name) }
    it { is_expected.to allow_value('CSC108!.2021 Fall').for(:display_name) }
    it { is_expected.to allow_value('CSC108-2021-Fall').for(:display_name) }
    it { is_expected.to have_many(:assignments) }
    it { is_expected.to have_many(:grade_entry_forms) }
    it { is_expected.to have_many(:sections) }
    it { is_expected.to have_many(:groups) }
    it { is_expected.to allow_value(true).for(:is_hidden) }
    it { is_expected.to allow_value(false).for(:is_hidden) }
    it { is_expected.not_to allow_value(nil).for(:is_hidden) }
    it { is_expected.to validate_numericality_of(:max_file_size).is_greater_than_or_equal_to(0) }
    it { is_expected.to allow_value(nil).for(:start_at) }
    it { is_expected.to allow_value(nil).for(:end_at) }

    it 'fail with error message when invalid name format' do
      course.name = 'Invalid!@'
      error_key = 'activerecord.errors.models.course.attributes.name.invalid'
      expected_error = I18n.t(error_key, attribute: 'Name')
      expect(course).not_to be_valid
      expect(course.errors[:name]).to include(expected_error)
    end

    describe 'start and end date' do
      it 'is valid when both start_at and end_at are nil' do
        course = build(:course, start_at: nil, end_at: nil)
        expect(course).to be_valid
      end

      it 'is valid when start_at is earlier than end_at' do
        course = build(:course, start_at: Time.zone.parse('2026-01-05'), end_at: Time.zone.parse('2026-04-05'))
        expect(course).to be_valid
      end

      it 'is valid when start_at equals end_at' do
        course = build(:course, start_at: Time.zone.parse('2026-01-05'), end_at: Time.zone.parse('2026-01-05'))
        expect(course).to be_valid
      end

      it 'is invalid when start_at is later than end_at' do
        course = build(:course, start_at: Time.zone.parse('2026-01-05'), end_at: Time.zone.parse('2026-01-04'))
        expect(course).not_to be_valid
        expect(course.errors[:start_at]).to include('must be before or equal to end date')
      end
    end
  end

  context 'callbacks' do
    describe '#update_repo_max_file_size' do
      # a course should be the only thing created here, if that ever changes, make sure the db is cleaned properly
      after { course.destroy! }

      shared_examples 'when not using git repos' do
        before { allow(Settings.repository).to receive(:type).and_return('mem') }

        it 'should not schedule a background job' do
          expect(UpdateRepoMaxFileSizeJob).not_to receive(:perform_later).with(course.id)
          subject
        end
      end

      shared_context 'git repos' do
        before do
          allow(Settings.repository).to receive(:type).and_return('git')
          allow(GitRepository).to receive(:purge_all)
        end

        after { FileUtils.rm_r(Dir.glob(File.join(Repository::ROOT_DIR, '*'))) }
      end

      context 'after creation' do
        subject { course }

        context 'when using git repos' do
          include_context 'git repos'
          it 'should schedule a background job' do
            expect(UpdateRepoMaxFileSizeJob).to receive(:perform_later)
            subject
          end
        end

        it_behaves_like 'when not using git repos'
      end

      context 'after save to max_file_size' do
        subject { course.update! max_file_size: course.max_file_size + 10_000 }

        before { course }

        context 'when using git repos' do
          include_context 'git repos'
          after { FileUtils.rm_r(Dir.glob(File.join(Repository::ROOT_DIR, '*'))) }

          it 'should schedule a background job' do
            expect(UpdateRepoMaxFileSizeJob).to receive(:perform_later).with(course.id)
            subject
          end
        end

        it_behaves_like 'when not using git repos'
      end

      context 'after save to something else' do
        subject { course.update! display_name: "#{course.display_name}abc" }

        before { course }

        context 'when using git repos' do
          include_context 'git repos'
          it 'should not schedule a background job' do
            expect(UpdateRepoMaxFileSizeJob).not_to receive(:perform_later).with(course.id)
            subject
          end
        end

        it_behaves_like 'when not using git repos'
      end
    end

    context 'The repository permissions file' do
      context 'should be updated' do
        it 'when changing toggling the hidden status for a course' do
          expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
          course.update(is_hidden: true)
        end
      end
    end
  end

  describe '#get_assignment_list' do
    context 'when file_format = yml' do
      context 'when there are no assignments in the course' do
        it 'should return a yml representation of the assignments in a course with no assignments' do
          result = course.get_assignment_list('yml')
          expected = { assignments: [] }.to_yaml
          expect(result).to eq(expected)
        end
      end

      context 'when the course has a single assignment' do
        # NOTE: the created assignment must be reloaded as the value for assignment1.due_date stored in the database is
        # less precise than that stored by ruby.
        let!(:assignment1) { create(:assignment, due_date: 5.days.ago, course: course).reload }

        it 'should return a yml representation of the assignments in a course with a single assignment' do
          result = course.get_assignment_list('yml')
          expected = { assignments: [create_assignment_symbol_to_value_map(assignment1)] }.to_yaml
          expect(result).to eq(expected)
        end
      end

      context 'when the course has multiple assignments' do
        let!(:assignment1) { create(:assignment, due_date: 5.days.ago, course: course).reload }
        let!(:assignment2) { create(:assignment, due_date: 1.day.ago, course: course).reload }
        let!(:assignment3) { create(:assignment, due_date: 8.days.from_now, course: course).reload }

        it 'should return a yml representation of the assignments in a course with multiple assignments' do
          result = course.get_assignment_list('yml')
          expected = { assignments: [create_assignment_symbol_to_value_map(assignment1),
                                     create_assignment_symbol_to_value_map(assignment2),
                                     create_assignment_symbol_to_value_map(assignment3)] }.to_yaml
          expect(result).to eq(expected)
        end
      end
    end

    context 'when file_format = csv' do
      context 'when there are no assignments in the course' do
        it 'should return a csv representation of the assignments in a course with no assignments aka an empty' \
           'string' do
          result = course.get_assignment_list('csv')
          expect(result).to eq('')
        end
      end

      context 'when the course has a single assignment' do
        let!(:assignment1) { create(:assignment, due_date: 5.days.ago, course: course) }

        it 'should return a csv representation of the assignments in a course with a single assignment' do
          result = course.get_assignment_list('csv').to_s
          expected_result = create_assignment_csv_string(assignment1)
          expect(result).to eq(expected_result)
        end
      end

      context 'when the course has multiple assignments' do
        let!(:assignment1) { create(:assignment, due_date: 5.days.ago, course: course) }
        let!(:assignment2) { create(:assignment, due_date: 1.day.ago, course: course) }
        let!(:assignment3) { create(:assignment, due_date: 8.days.from_now, course: course) }

        it 'should return a csv representation of the assignments in a course with multiple assignments' do
          result = course.get_assignment_list('csv').to_s
          expected_result = ''
          [assignment1, assignment2, assignment3].each do |assignment|
            expected_result += create_assignment_csv_string(assignment)
          end
          expect(result).to eq(expected_result)
        end
      end
    end
  end

  describe '#upload_assignment_list' do
    context 'when file_format = \'csv\'' do
      context 'when the file contains no assignments' do
        it 'should not change the state of the database' do
          # get assignments associated with a course before uploading assignments
          assignments_before_upload = course.assignments.to_a

          course.upload_assignment_list('csv', [].to_csv)

          # reload the course so that we can see if the state of the course has changed in the database
          course.reload

          assignments_after_upload = course.assignments.to_a

          # Expect there to be no stored assignments in the database
          expect(assignments_after_upload).to eq(assignments_before_upload)
        end
      end

      context 'when the file contains a single assignment' do
        context 'when the assignment already exists and an attribute is changed' do
          let(:assignment) do
            create(:assignment, course: course, short_identifier: 'TEST', message: 'a', is_hidden: false,
                                description: 'ello', due_date: 5.days.from_now)
          end

          before do
            # desired list of assignment attributes
            assignment_values = Assignment::DEFAULT_FIELDS.map do |f|
              f == :message ? 'b' : assignment.public_send(f)
            end

            # csv representation of the single assignment
            csv = assignment_values.to_csv

            # The only attribute to have changed is b
            course.upload_assignment_list('csv', csv)
            assignment.reload
          end

          it 'should update the attributes that were changed' do
            expect(assignment.message).to eq('b')
          end

          it 'should not create a new assignment' do
            expect(course.assignments.length).to eq(1)
          end
        end

        context 'when the assignment is new to the database' do
          let(:desired_attributes) do
            ['short_identifier', 'description', 1.day.from_now.at_beginning_of_minute, 'message',
             1, 2, 1, true, true, 2.days.from_now.at_beginning_of_minute, 'remark_message',
             true, true, false, true, true, true, true, false, nil, nil, true, true]
          end
          let(:assignment) do
            csv = desired_attributes.to_csv
            course.upload_assignment_list('csv', csv)
            course.assignments.find_by(short_identifier: 'short_identifier')
          end

          it 'should set assignment_properties.repository_folder, token_period and ' \
             'unlimited_tokens to pre-determined values' do
            expect(assignment.assignment_properties.repository_folder).to eq('short_identifier')
            expect(assignment.assignment_properties.token_period).to eq(1)
            expect(assignment.assignment_properties.unlimited_tokens).to be(false)
          end

          it 'should save the new object to the database with the intended attributes' do
            # Check that all the desired attributes match those stored in the assignment
            Assignment::DEFAULT_FIELDS.length.times do |index|
              expect(assignment.public_send(
                       Assignment::DEFAULT_FIELDS[index]
                     )).to eq(desired_attributes[index])
            end
          end
        end
      end

      context 'when there are multiple assignments' do
        context 'when some rows of the csv are valid and others are invalid' do
          let!(:csv) do
            # creating 2 rows only containing invalid short identifiers
            ['{:}', 'a'].to_csv + ['^_^', 'a'].to_csv +
              # adding 2 valid rows
              ['row_1', 'description', 1.day.from_now.at_beginning_of_minute, 'message'].to_csv +
              ['row_2', 'description', 1.day.from_now.at_beginning_of_minute, 'message'].to_csv
          end

          it 'should return a hash mapping \'invalid_lines\' to a string representation of all' \
             'invalid lines and \'valid_lines\' to a string telling us how many valid lines were successfully' \
             'uploaded' do
            actual = course.upload_assignment_list('csv', csv)
            expected_invalid_lines = 'The following CSV rows were invalid: {:},a - ^_^,a'

            expected_valid_lines = '2 objects successfully uploaded.'

            expect(expected_invalid_lines).to eq(actual[:invalid_lines])
            expect(expected_valid_lines).to eq(actual[:valid_lines])
          end

          it 'should set the attributes of the rows changed' do
            course.upload_assignment_list('csv', csv)
            course.reload
            # check that the two new records are created and that the attributes match with the ones set
            2.times do |index|
              row = ["row_#{index + 1}", 'description', 1.day.from_now.at_beginning_of_minute, 'message']
              assignment = course.assignments.find_by(short_identifier: "row_#{index + 1}")

              # Check that the assignment exists in the database
              expect(assignment).not_to be_nil

              # Checking that the attributes of the stored object match those specified in row
              4.times do |j|
                expect(assignment.public_send(
                         Assignment::DEFAULT_FIELDS[j]
                       )).to eq(row[j])
              end
            end
          end
        end
      end
    end

    context 'when file_format = \'YML\'' do
      context 'when the file contains no assignments' do
        it 'should not change the state of the database' do
          # get assignments associated with a course before uploading assignments
          assignments_before_upload = course.assignments.to_a
          course.upload_assignment_list('yml', parse_yaml_content({ 'assignments' => [] }.to_yaml))

          # reload the course so that we can see if the state of the course has changed in the database
          course.reload

          assignments_after_upload = course.assignments.to_a

          expect(assignments_after_upload).to eq(assignments_before_upload)
        end
      end

      context 'when the file contains a single assignment' do
        context 'when the assignment already exists and an attribute is changed' do
          let(:assignment) do
            create(:assignment, course: course, short_identifier: 'TEST', message: 'a', is_hidden: false,
                                description: 'ello', due_date: 5.days.from_now)
          end

          before do
            # hash from attribute names to their desired values
            assignment_values = Assignment::DEFAULT_FIELDS.zip(
              Assignment::DEFAULT_FIELDS.map do |f|
                f == :message ? 'b' : assignment.public_send(f)
              end
            ).to_h
            yaml = parse_yaml_content({ 'assignments' => [assignment_values] }.to_yaml)

            course.upload_assignment_list('yml', yaml)
            assignment.reload
          end

          it 'should update the attributes that were changed' do
            expect(assignment.message).to eq('b')
          end

          it 'should not create a new assignment' do
            expect(course.assignments.length).to eq(1)
          end
        end

        context 'when the assignment is new to the database' do
          let(:desired_attributes) do
            ['short_identifier', 'description', 1.day.from_now.at_beginning_of_minute, 'message',
             1, 2, 1, true, true, 2.days.from_now.at_beginning_of_minute, 'remark_message',
             true, true, false, true, true, true, true, false, nil, nil, true, true]
          end
          let(:assignment) do
            desired_attribute_value_hash = Assignment::DEFAULT_FIELDS.zip(desired_attributes).to_h
            yaml = parse_yaml_content({ 'assignments' => [desired_attribute_value_hash] }.to_yaml)
            course.upload_assignment_list('yml', yaml)
            course.assignments.find_by(short_identifier: 'short_identifier')
          end

          it 'should set assignment_properties.repository_folder, token_period and ' \
             'unlimited_tokens to pre-determined values' do
            expect(assignment.assignment_properties.repository_folder).to eq('short_identifier')
            expect(assignment.assignment_properties.token_period).to eq(1)
            expect(assignment.assignment_properties.unlimited_tokens).to be(false)
          end

          it 'should save the new object to the database with the intended attributes' do
            # Check that all attributes stored in the assignment match the desired attributes
            Assignment::DEFAULT_FIELDS.length.times do |index|
              expect(assignment.public_send(
                       Assignment::DEFAULT_FIELDS[index]
                     )).to eq(desired_attributes[index])
            end
          end
        end
      end

      context 'when there are multiple assignments' do
        context 'when some assignments are new, others are old' do
          let!(:new_assignment_attr) do
            ['new', 'abc', 1.day.from_now.at_beginning_of_minute, 'message',
             1, 2, 1, true, true, 2.days.from_now.at_beginning_of_minute, 'remark_message',
             true, true, false, true, true, true, true, false, nil, nil, true, false]
          end
          let!(:returned) do
            # create the old assignment
            create(:assignment, course: course, short_identifier: 'old', is_hidden: false,
                                description: 'ello', due_date: 5.days.from_now)
            # Create a hash mapping assignment attributes to desired values (to be used when setting attributes for old
            # assignment)
            old_assignment_new_attr = { short_identifier: 'old', description: 'Hello' }

            # Create a hash mapping assignment attributes to desired values (to be used when setting attributes for new
            # assignment)
            new_assignment_attr_hash = Assignment::DEFAULT_FIELDS.zip(new_assignment_attr).to_h

            # create a new yml file using old_assignment_attr_hash and new_assignment_attr_hash
            yaml = parse_yaml_content({ 'assignments' => [
              old_assignment_new_attr, new_assignment_attr_hash
            ] }.to_yaml)
            course.upload_assignment_list('yml', yaml)
          end
          let!(:old_assignment) { course.assignments.find_by(short_identifier: 'old') }
          let!(:new_assignment) { course.assignments.find_by(short_identifier: 'new') }

          it 'should add the new assignment, setting the repository_folder, token_period, unlimited_tokens' \
             'and all user specified attributes to to specified values' do
            # Check that attributes are properly set for the new assignment
            expect(new_assignment.assignment_properties.repository_folder).to eq('new')
            expect(new_assignment.assignment_properties.token_period).to eq(1)
            expect(new_assignment.assignment_properties.unlimited_tokens).to be(false)

            Assignment::DEFAULT_FIELDS.length.times do |index|
              expect(new_assignment.public_send(
                       Assignment::DEFAULT_FIELDS[index]
                     )).to eq(new_assignment_attr[index])
            end
          end

          it 'should correctly update the old assignment\'s attributes with ones specified by the user' do
            expect(old_assignment.description).to eq('Hello')
          end

          it 'should return a list with the success status of saving each row to the database' do
            expect(returned).to eq([true, true])
          end

          it 'should not add any new courses not specified in the yml file' do
            expect(old_assignment).not_to be_nil
            expect(new_assignment).not_to be_nil
            expect(course.assignments.to_a.length).to eq(2)
          end
        end
      end
    end
  end

  describe '#get_required_files' do
    let(:actual) { assignment.course.get_required_files }
    let(:matching) { actual.lines.filter_map { |line| line.chomp if /^#{assignment.repository_folder}/.match?(line) } }

    context 'when a course has no assignments' do
      it 'should return an empty string' do
        expect(course.get_required_files).to eq('')
      end
    end

    context 'when a course has one assignment' do
      context 'when the result from the assignment query does not return the assignment' do
        context 'when the assignment is a scanned exam and not hidden' do
          let(:assignment) { create(:assignment_for_scanned_exam) }

          it 'should return an empty string' do
            expect(actual).to eq('')
          end
        end

        context 'when the assignment is hidden' do
          let(:assignment) { create(:assignment, is_hidden: true) }

          it 'should return an empty string' do
            expect(actual).to eq('')
          end
        end
      end

      context 'when an assignment has no require files' do
        context 'when assignment.only_required_files is false' do
          let(:assignment) { create(:assignment, only_required_files: false) }

          it 'should return an empty string' do
            expect(actual).to eq('')
          end
        end

        context 'when assignment.only_required_files is true' do
          let(:assignment) { create(:assignment, only_required_files: true) }

          it 'should return an empty string' do
            expect(actual).to eq('')
          end
        end
      end

      context 'when an assignment has required files' do
        before do
          create(:assignment_file, assignment: assignment, filename: 'a')
          create(:assignment_file, assignment: assignment, filename: 'b')
        end

        context 'when assignment.only_required_files is false' do
          let(:assignment) do
            create(:assignment, assignment_properties_attributes: { only_required_files: false })
          end

          it 'should include both files in the matching lines' do
            repo_folder = assignment.repository_folder
            expect(matching).to contain_exactly("#{repo_folder}/a false", "#{repo_folder}/b false")
          end
        end

        context 'when assignment.only_required_files is true' do
          let(:assignment) do
            create(:assignment, assignment_properties_attributes: { only_required_files: true })
          end

          it 'should include both files in the matching lines' do
            repo_folder = assignment.repository_folder
            expect(matching).to contain_exactly("#{repo_folder}/a true", "#{repo_folder}/b true")
          end
        end
      end
    end

    context 'when a course has multiple assignments' do
      let(:assignments) { create_list(:assignment, 2, course: course) }
      let(:expected) { assignments.map { |_| [] } }

      before do
        create(:assignment_file, assignment: assignments.last, filename: 'a')
        create(:assignment_file, assignment: assignments.last, filename: 'b')
      end

      context 'and the assignment has no required files' do
        let(:assignment) { assignments.first }

        it 'should not find any matching lines for the given assignment' do
          expect(matching).to be_empty
        end
      end

      context 'and the assignment has required files' do
        let(:assignment) { assignments.last }

        it 'should include both files in the matching lines' do
          repo_folder = assignment.repository_folder
          expect(matching).to contain_exactly("#{repo_folder}/a false", "#{repo_folder}/b false")
        end
      end
    end
  end

  describe '#get_current_assignment' do
    context 'when no assignments are found' do
      it 'returns nil' do
        result = course.get_current_assignment
        expect(result).to be_nil
      end
    end

    context 'when one assignment is found' do
      let!(:assignment1) { create(:assignment, due_date: 5.days.ago, course: course) }

      it 'returns the only assignment' do
        result = course.get_current_assignment
        expect(result).to eq(assignment1)
      end
    end

    context 'when more than one assignment is found' do
      let!(:assignments) do
        due_dates.map do |due_date|
          create(:assignment, due_date: due_date, course: course)
        end
      end

      context 'when there is an assignment due in 3 days' do
        let(:due_dates) { [5.days.ago, 3.days.from_now] }

        it 'returns the assignment due in 3 days' do
          result = course.get_current_assignment
          expect(result).to eq(assignments[1])
        end
      end

      context 'when the next assignment is due in more than 3 days' do
        let(:due_dates) { [5.days.ago, 1.day.ago, 8.days.from_now] }

        it 'returns the assignment that was most recently due' do
          result = course.get_current_assignment
          expect(result).to eq(assignments[1])
        end
      end

      context 'when all assignments are due in more than 3 days' do
        let(:due_dates) { [5.days.from_now, 12.days.from_now, 19.days.from_now] }

        it 'returns the assignment that is due first' do
          result = course.get_current_assignment
          expect(result).to eq(assignments[0])
        end
      end

      context 'when all assignments are past the due date' do
        let(:due_dates) { [5.days.ago, 12.days.ago, 19.days.ago] }

        it 'returns the assignment that was due most recently' do
          result = course.get_current_assignment
          expect(result).to eq(assignments[0])
        end
      end
    end
  end

  describe '#export_student_data_csv' do
    context 'when there are no students in the course' do
      it 'returns empty string' do
        result = course.export_student_data_csv
        expect(result).to eq('')
      end
    end

    context 'when there is a student in the course' do
      let!(:user1) { create(:end_user) }

      before { create(:student, user: user1, course: course) }

      it 'returns the data of the student' do
        result = course.export_student_data_csv
        expect(result).to eq("#{user1.user_name},#{user1.last_name},#{user1.first_name},,,#{user1.email}\n")
      end
    end

    context 'where there are multiple students in the course' do
      let!(:user1) { create(:end_user) }
      let!(:user2) { create(:end_user) }

      before do
        create(:student, user: user1, course: course)
        create(:student, user: user2, course: course)
      end

      it 'returns the data of the students' do
        result = course.export_student_data_csv

        student1_data = "#{user1.user_name},#{user1.last_name},#{user1.first_name},,,#{user1.email}\n"
        student2_data = "#{user2.user_name},#{user2.last_name},#{user2.first_name},,,#{user2.email}\n"
        student_data = [student1_data, student2_data]
        expected = student_data.sort.join
        expect(result).to eq(expected)
      end
    end
  end

  describe '#export_student_data_yml' do
    context 'where there are no students in the course' do
      it 'returns empty yaml object' do
        result = course.export_student_data_yml
        expect(result).to eq([].to_yaml)
      end
    end

    context 'where there is a student in the course' do
      let!(:user1) { create(:end_user) }

      before { create(:student, user: user1, course: course) }

      it 'returns the data of the student' do
        result = course.export_student_data_yml
        expected = [{ user_name: user1.user_name,
                      last_name: user1.last_name,
                      first_name: user1.first_name,
                      email: user1.email,
                      id_number: nil,
                      section_name: nil }]
        expect(result).to eq(expected.to_yaml)
      end
    end

    context 'when there are multiple students in the course' do
      let!(:user1) { create(:end_user) }
      let!(:user2) { create(:end_user) }

      before do
        create(:student, user: user1, course: course)
        create(:student, user: user2, course: course)
      end

      it 'returns the data of the students' do
        result = course.export_student_data_yml

        student1_data = {
          user_name: user1.user_name,
          last_name: user1.last_name,
          first_name: user1.first_name,
          email: user1.email,
          id_number: nil,
          section_name: nil
        }

        student2_data = {
          user_name: user2.user_name,
          last_name: user2.last_name,
          first_name: user2.first_name,
          email: user2.email,
          id_number: nil,
          section_name: nil
        }
        expected = [student1_data, student2_data].sort_by { |a| a[:user_name] }
        expect(result).to eq(expected.to_yaml)
      end
    end
  end
end

# Parse the +yaml_string+ and return the data as a hash.
def parse_yaml_content(yaml_string)
  YAML.safe_load(yaml_string,
                 permitted_classes: [
                   Date, Time, Symbol, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone,
                   ActiveSupport::Duration, ActiveSupport::HashWithIndifferentAccess
                 ],
                 aliases: true)
end

def create_assignment_csv_string(assignment)
  # returns a csv formatted string for an assignment where each attribute
  # specified by Assignment::DEFAULT_FIELDS appears in the same order as initialized
  # and is comma separated.
  [assignment.short_identifier, assignment.description, assignment.due_date, assignment.message,
   assignment.group_min, assignment.group_max, assignment.tokens_per_period, assignment.allow_web_submits,
   assignment.student_form_groups, assignment.remark_due_date, assignment.remark_message,
   assignment.assign_graders_to_criteria, assignment.enable_test, assignment.enable_student_tests,
   assignment.allow_remarks, assignment.display_grader_names_to_students, assignment.display_median_to_students,
   assignment.group_name_autogenerated, assignment.is_hidden, assignment.visible_on, assignment.visible_until,
   assignment.vcs_submit, assignment.has_peer_review].to_csv
end

def create_assignment_symbol_to_value_map(assignment)
  # returns a mapping of attribute symbols present in Assignment::DEFAULT_FIELDS to
  # their associated value in the variable a where a is an assignment.
  { short_identifier: assignment.short_identifier,
    description: assignment.description,
    due_date: assignment.due_date,
    message: assignment.message,
    is_hidden: assignment.is_hidden,
    visible_on: assignment.visible_on,
    visible_until: assignment.visible_until,
    assignment_properties_attributes: {
      group_min: assignment.group_min,
      group_max: assignment.group_max,
      tokens_per_period: assignment.tokens_per_period,
      allow_web_submits: assignment.allow_web_submits,
      student_form_groups: assignment.student_form_groups,
      remark_due_date: assignment.remark_due_date,
      remark_message: assignment.remark_message,
      assign_graders_to_criteria: assignment.assign_graders_to_criteria,
      enable_test: assignment.enable_test,
      enable_student_tests: assignment.enable_student_tests,
      allow_remarks: assignment.allow_remarks,
      display_grader_names_to_students: assignment.display_grader_names_to_students,
      display_median_to_students: assignment.display_median_to_students,
      group_name_autogenerated: assignment.group_name_autogenerated,
      vcs_submit: assignment.vcs_submit,
      has_peer_review: assignment.has_peer_review
    } }
end
