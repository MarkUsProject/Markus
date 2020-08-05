describe CourseSummaryPolicy do
  include PolicyHelper
  describe 'When the user is admin' do
    subject { described_class.new(user: user) }
    let(:user) { build(:admin) }
    context 'Admin can view course summary' do
      it { is_expected.to pass :view_course_summary? }
    end
    context 'Admin can download csv grader report' do
      it { is_expected.to pass :download_csv_grades_report? }
    end
    context 'Admin can manage marking schemes' do
      it { is_expected.to pass :marking_schemes? }
    end
  end
  describe 'When the user is grader' do
    subject { described_class.new(user: user) }
    let(:user) { create(:ta) }
    context 'When grader is allowed to manage marking schemes and view grades summary' do
      before do
        user.grader_permission.manage_course_grades = true
        user.grader_permission.save
      end
      it { is_expected.to pass :view_course_summary? }
      it { is_expected.to pass :download_csv_grades_report? }
      it { is_expected.to pass :marking_schemes? }
    end
    context 'When grader is not allowed to manage marking schemes and view grades summary' do
      before do
        user.grader_permission.manage_course_grades = false
        user.grader_permission.save
      end
      it { is_expected.not_to pass :view_course_summary? }
      it { is_expected.not_to pass :download_csv_grades_report? }
      it { is_expected.not_to pass :marking_schemes? }
    end
  end
end
