describe FeedbackFile do
  context 'submission and test_group_result are both set' do
    let(:test_group_result) { build(:test_group_result) }
    let(:course) { test_group_result.course }
    let(:submission) do
      build(:submission, grouping: build(:grouping, assignment: build(:assignment, course: course)))
    end
    let(:feedback_file) { build(:feedback_file, submission: submission, test_group_result: test_group_result) }
    context 'when the submission and test_group_result are from different courses' do
      let(:course) { build(:course) }
      it 'should fail a validation' do
        expect(feedback_file).not_to be_valid
      end
    end
    context '#course' do
      it 'should have the same course as its associations' do
        expect(feedback_file.course).to eq(submission.course)
        expect(feedback_file.course).to eq(test_group_result.course)
      end
    end
  end

  it 'is valid when associated with a submission but not a test_group_result' do
    submission = create(:submission)
    feedback_file = build(:feedback_file, submission: submission)
    expect(feedback_file).to be_valid
  end

  it 'is valid when associated with a test_group_result but not a submission' do
    test_group_result = create(:test_group_result)
    feedback_file = build(:feedback_file_with_test_run, test_group_result: test_group_result)
    expect(feedback_file).to be_valid
  end

  it 'is not valid when missing both submission and test_group_result association' do
    feedback_file = build(:feedback_file, submission: nil)
    expect(feedback_file).to_not be_valid
  end
end
