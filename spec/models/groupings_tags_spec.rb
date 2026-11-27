describe GroupingsTags do
  subject { build(:groupings_tags, grouping: grouping, tag: tag) }

  let(:assignment) { create(:assignment) }
  let(:grouping) { create(:grouping, assignment: assignment) }
  let(:tag) { create(:tag, role: create(:instructor, course: assignment.course)) }

  it { is_expected.to belong_to(:grouping) }
  it { is_expected.to belong_to(:tag) }
  it { is_expected.to have_one(:course) }

  it 'is invalid when the grouping and tag belong to different courses' do
    tag.role.update!(course: create(:course))
    tag.reload

    expect(subject).not_to be_valid
  end

  it 'is valid when the tag is not associated with an assignment' do
    expect(subject).to be_valid
  end

  it 'is valid when the tag and grouping belong to the same assignment' do
    tag.update!(assessment: assignment)

    expect(subject).to be_valid
  end

  it 'is invalid when the tag and grouping belong to different assignments' do
    tag.update!(assessment: create(:assignment, course: assignment.course))

    expect(subject).not_to be_valid
    expect(subject.errors[:base]).to include(
      I18n.t('activerecord.errors.models.groupings_tags.different_assignment_grouping')
    )
  end
end
