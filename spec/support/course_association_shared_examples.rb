include CourseAssociationHelper
shared_examples 'course associations' do
  it 'should be valid when all belongs_to associations belong to the same course' do
    expect(subject).to be_valid
  end
  it 'should not be valid when one of the belongs_to associations is different from the rest' do
    set_course!(subject, create(:course))
    expect(subject.reload).not_to be_valid
  end
end
