describe AssignmentFile do
  it { is_expected.to belong_to(:assignment) }
  it { is_expected.to validate_presence_of(:filename) }
  describe 'uniqueness validation' do
    subject { create(:assignment_file) }
    it { is_expected.to validate_uniqueness_of(:filename).scoped_to(:assessment_id) }
  end

  it { is_expected.to allow_value('est.java').for(:filename) }
  it { is_expected.not_to allow_value('"éàç_(*8').for(:filename) }
  it { is_expected.to have_one(:course) }
end
