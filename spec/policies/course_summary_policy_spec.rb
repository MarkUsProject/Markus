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
  describe 'When the user is TA' do
    subject { described_class.new(user: user) }
    let(:user) { create(:ta) }
    context 'TA can view course summary if they are allowed to download grades report or manage marking schemes' do
      before do
        create(:grader_permission, user_id: user.id, download_grades_report: true, manage_marking_schemes: false)
      end
      it { is_expected.to pass :view_course_summary? }
    end
    context 'TA cannot view course summary if they are not allowed to
             download grades report and manage marking schemes' do
      before do
        create(:grader_permission, user_id: user.id, download_grades_report: false, manage_marking_schemes: false)
      end
      it { is_expected.not_to pass :view_course_summary? }
    end
    context 'When TA is allowed to download csv grades report' do
      before do
        create(:grader_permission, user_id: user.id, download_grades_report: true)
      end
      it { is_expected.to pass :download_csv_grades_report? }
    end
    context 'When TA is not allowed to download csv grades report' do
      before do
        create(:grader_permission, user_id: user.id, download_grades_report: false)
      end
      it { is_expected.not_to pass :download_csv_grades_report? }
    end
    context 'When TA is allowed to manage marking schemes' do
      before do
        create(:grader_permission, user_id: user.id, manage_marking_schemes: true)
      end
      it { is_expected.to pass :marking_schemes? }
    end
    context 'When TA is not allowed to manage marking schemes' do
      before do
        create(:grader_permission, user_id: user.id, manage_marking_schemes: false)
      end
      it { is_expected.not_to pass :marking_schemes? }
    end
  end
end
