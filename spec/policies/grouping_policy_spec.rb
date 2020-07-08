describe GroupingPolicy do
  include PolicyHelper

  describe '#run_tests?' do
    subject { described_class.new(grouping, user: user) }

    context 'when the user is an admin' do
      let(:user) { build(:admin) }

      context 'if the assignment policy passes' do
        let(:assignment) { create(:assignment_for_tests) }
        let(:grouping) { build_stubbed(:grouping, assignment: assignment) }
        it { is_expected.to pass :run_tests? }
      end
    end

    context 'when the user is a student' do
      let(:user) { build(:student) }

      context 'if the assignment policy passes' do
        let(:assignment) { create(:assignment_for_student_tests) }
        let(:grouping) { create(:grouping, assignment: assignment, test_tokens: 0) }

        context 'if the student is not a member of the group' do
          let(:other_student) { create(:student) }
          let!(:membership) { create(:accepted_student_membership, user: other_student, grouping: grouping) } # non-lazy
          it { is_expected.not_to pass :run_tests?, because_of: :member? }
        end

        context 'if the student is a member of the group' do
          let!(:membership) { create(:accepted_student_membership, user: user, grouping: grouping) } # non-lazy

          context 'if a test run is in progress' do
            let!(:test_run) { create(:test_run, user: user, grouping: grouping) } # non-lazy
            it { is_expected.not_to pass :run_tests?, because_of: :not_in_progress? }
          end

          context 'if a test run is not in progress' do
            let(:test_run) { create(:test_run, user: user, grouping: grouping) }
            let!(:test_group_result) { create(:test_group_result, test_run: test_run) } # non-lazy

            context 'if the student has tokens available' do
              let(:grouping) { create(:grouping, assignment: assignment, test_tokens: 1) }
              it { is_expected.to pass :run_tests? }
            end

            context 'if the student has no tokens available' do
              context 'if the assignment has no unlimited tokens' do
                it { is_expected.not_to pass :run_tests?, because_of: :tokens_available? }
              end

              context 'if the assignment has unlimited tokens' do
                let(:assignment) do
                  create(:assignment_for_student_tests, assignment_properties_attributes: { unlimited_tokens: true })
                end
                it { is_expected.to pass :run_tests? }
              end
            end
          end
        end
      end
    end
  end

  describe '#view_file_manager?' do
    subject { described_class.new(grouping, user: user) }
    context 'as an admin' do
      let(:user) { create :admin }
      let(:grouping) { create :grouping }
      it { is_expected.not_to pass :view_file_manager? }
    end
    context 'as a grader' do
      let(:user) { create :ta }
      let(:grouping) { create :grouping }
      it { is_expected.not_to pass :view_file_manager? }
    end
    context 'as a student' do
      let(:user) { create :student }
      context 'when the assignment is a regular one' do
        let(:grouping) { create :grouping }
        it { is_expected.to pass :view_file_manager? }
      end
      context 'when the assignment is scanned' do
        let(:grouping) { create :grouping, assignment: create(:assignment_for_scanned_exam) }
        it { is_expected.not_to pass :view_file_manager? }
      end
      context 'when the assignment is a peer review' do
        let(:grouping) { create :grouping, assignment: create(:peer_review_assignment) }
        it { is_expected.not_to pass :view_file_manager? }
      end
      context 'when the assignment is timed' do
        let(:grouping) { create :grouping, assignment: create(:timed_assignment) }
        context 'when the grouping has not started' do
          it { is_expected.not_to pass :view_file_manager? }
        end
        context 'when the grouping has started' do
          before { grouping.update!(start_time: 1.hour.ago) }
          it { is_expected.to pass :view_file_manager? }
        end
      end
    end
  end

  describe '#start_timed_assignment?' do
    subject { described_class.new(grouping, user: user) }
    context 'as an admin' do
      let(:user) { create :admin }
      let(:grouping) { create :grouping }
      it { is_expected.not_to pass :start_timed_assignment? }
    end
    context 'as a grader' do
      let(:user) { create :ta }
      let(:grouping) { create :grouping }
      it { is_expected.not_to pass :start_timed_assignment? }
    end
    context 'as a student' do
      let(:user) { create :student }
      let(:assignment) { create :timed_assignment }
      let(:grouping) { create :grouping_with_inviter, inviter: user, assignment: assignment }
      it { is_expected.to pass :start_timed_assignment? }
      context 'when the grouping has already started the assignment' do
        before { grouping.update!(start_time: 1.hour.ago) }
        it { is_expected.not_to pass :start_timed_assignment? }
      end
      context 'when the collection date has passed' do
        before { assignment.update!(due_date: 1.minute.ago) }
        it { is_expected.not_to pass :start_timed_assignment? }
      end
      context 'when the assignment start time has not started yet' do
        before { assignment.update!(due_date: 10.hours.from_now, start_time: 1.minute.from_now) }
        it { is_expected.not_to pass :start_timed_assignment? }
      end
    end
  end
end
