describe GradeEntryFormPolicy do
  include PolicyHelper
  describe 'When the user is admin' do
    subject { described_class.new(user: user) }
    let(:user) { build(:admin) }
    context 'Admin can create, edit, update the grade entry forms' do
      it { is_expected.to pass :manage? }
    end
    context 'Admin can view, update, download and upload grades' do
      it { is_expected.to pass :grading? }
    end
    context 'Admin can release or unrelease the grades' do
      it { is_expected.to pass :update_grade_entry_students? }
    end
    context 'Admin cannot use the student interface' do
      it { is_expected.not_to pass :student_interface? }
    end
  end
  describe 'When the user is TA' do
    subject { described_class.new(user: user) }
    let(:user) { create(:ta) }
    context 'When TA is allowed to create, edit, update the grade entry forms' do
      before do
        user.grader_permission.manage_assignments = true
        user.grader_permission.save
      end
      it { is_expected.to pass :manage? }
    end
    context 'When TA is not allowed to create, edit, update the grade entry forms' do
      before do
        user.grader_permission.manage_assignments = false
        user.grader_permission.save
      end
      it { is_expected.not_to pass :manage? }
    end
    context 'When TA is allowed to release or unrelease the grades' do
      before do
        user.grader_permission.release_unrelease_grades = true
        user.grader_permission.save
      end
      it { is_expected.to pass :update_grade_entry_students? }
    end
    context 'When TA is not allowed to release or unrelease the grades' do
      before do
        user.grader_permission.release_unrelease_grades = false
        user.grader_permission.save
      end
      it { is_expected.not_to pass :update_grade_entry_students? }
    end
    context 'TA can view, update, download and upload grades' do
      it { is_expected.to pass :grading? }
    end
    context 'TA cannot use the student interface' do
      it { is_expected.not_to pass :student_interface? }
    end
  end
  describe 'When the user is student' do
    subject { described_class.new(user: user) }
    let(:user) { build(:student) }
    context 'Student cannot manage or access the grade entry forms' do
      it { is_expected.not_to pass :manage? }
      it { is_expected.not_to pass :grading? }
      it { is_expected.not_to pass :update_grade_entry_students? }
    end
    context 'Student can use the student interface' do
      it { is_expected.to pass :student_interface? }
    end
  end
end
