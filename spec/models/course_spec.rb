describe Course do
  let(:course) { create :course }
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
        after(:each) { FileUtils.rm_r(Dir.glob(File.join(Repository::ROOT_DIR, '*'))) }
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
        include_examples 'when not using git repos'
      end
      context 'after save to max_file_size' do
        before { course }
        subject { course.update! max_file_size: course.max_file_size + 10_000 }
        context 'when using git repos' do
          include_context 'git repos'
          after { FileUtils.rm_r(Dir.glob(File.join(Repository::ROOT_DIR, '*'))) }
          it 'should schedule a background job' do
            expect(UpdateRepoMaxFileSizeJob).to receive(:perform_later).with(course.id)
            subject
          end
        end
        include_examples 'when not using git repos'
      end
      context 'after save to something else' do
        before { course }
        subject { course.update! display_name: "#{course.display_name}abc" }
        context 'when using git repos' do
          include_context 'git repos'
          it 'should not schedule a background job' do
            expect(UpdateRepoMaxFileSizeJob).not_to receive(:perform_later).with(course.id)
            subject
          end
        end
        include_examples 'when not using git repos'
      end
    end
  end

  describe '#get_assignment_list' # TODO
  describe '#upload_assignment_list' # TODO
  describe '#get_required_files' # TODO

  describe '#get_current_assignment' do
    context 'when no assignments are found' do
      it 'returns nil' do
        result = course.get_current_assignment
        expect(result).to be_nil
      end
    end

    context 'when one assignment is found' do
      let!(:assignment1) { create :assignment, due_date: 5.days.ago, course: course }

      it 'returns the only assignment' do
        result = course.get_current_assignment
        expect(result).to eq(assignment1)
      end
    end

    context 'when more than one assignment is found' do
      context 'when there is an assignment due in 3 days' do
        let!(:assignment1) { create :assignment, due_date: 5.days.ago, course: course }
        let!(:assignment2) { create :assignment, due_date: 3.days.from_now, course: course }

        it 'returns the assignment due in 3 days' do
          result = course.get_current_assignment
          # should return assignment 2
          expect(result).to eq(assignment2)
        end
      end

      context 'when the next assignment is due in more than 3 days' do
        let!(:assignment1) { create :assignment, due_date: 5.days.ago, course: course }
        let!(:assignment2) { create :assignment, due_date: 1.day.ago, course: course }
        let!(:assignment3) { create :assignment, due_date: 8.days.from_now, course: course }

        it 'returns the assignment that was most recently due' do
          result = course.get_current_assignment
          # should return assignment 2
          expect(result).to eq(assignment2)
        end
      end

      context 'when all assignments are due in more than 3 days' do
        let!(:assignment1) { create :assignment, due_date: 5.days.from_now, course: course }
        let!(:assignment2) { create :assignment, due_date: 12.days.from_now, course: course }
        let!(:assignment3) { create :assignment, due_date: 19.days.from_now, course: course }

        it 'returns the assignment that is due first' do
          result = course.get_current_assignment
          # should return assignment 1
          expect(result).to eq(assignment1)
        end
      end

      context 'when all assignments are past the due date' do
        let!(:assignment1) { create :assignment, due_date: 5.days.ago, course: course }
        let!(:assignment2) { create :assignment, due_date: 12.days.ago, course: course }
        let!(:assignment3) { create :assignment, due_date: 19.days.ago, course: course }

        it 'returns the assignment that was due most recently' do
          result = course.get_current_assignment
          # should return assignment 1
          expect(result).to eq(assignment1)
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
      let!(:user1) { create :end_user }
      let!(:student1) { create :student, user: user1, course: course }
      it 'returns the data of the student' do
        result = course.export_student_data_csv
        expect(result).to eq("#{user1.user_name},#{user1.last_name},#{user1.first_name},,,#{user1.email}\n")
      end
    end

    context 'where there are multiple students in the course' do
      let!(:user1) { create :end_user }
      let!(:user2) { create :end_user }
      let!(:student1) { create :student, user: user1, course: course }
      let!(:student2) { create :student, user: user2, course: course }
      it 'returns the data of the students' do
        result = course.export_student_data_csv

        student1_data = "#{user1.user_name},#{user1.last_name},#{user1.first_name},,,#{user1.email}\n"
        student2_data = "#{user2.user_name},#{user2.last_name},#{user2.first_name},,,#{user2.email}\n"
        if user1.user_name <= user2.user_name
          expected = student1_data + student2_data
        else
          expected = student2_data + student1_data
        end
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
      let!(:user1) { create :end_user }
      let!(:student1) { create :student, user: user1, course: course }
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
      let!(:user1) { create :end_user }
      let!(:user2) { create :end_user }
      let!(:student1) { create :student, user: user1, course: course }
      let!(:student2) { create :student, user: user2, course: course }
      it 'returns the data of the students' do
        result = course.export_student_data_yml
        expected = []

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

        if user1.user_name <= user2.user_name
          expected.push(student1_data)
          expected.push(student2_data)
        else
          expected.push(student2_data)
          expected.push(student1_data)
        end
        expect(result).to eq(expected.to_yaml)
      end
    end
  end
end
