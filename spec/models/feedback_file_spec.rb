describe FeedbackFile do
  it 'is valid when associated with a submission but not a test_group_result' do
    submission = create :submission
    feedback_file = build :feedback_file, submission: submission
    expect(feedback_file).to be_valid
  end

  it 'is valid when associated with a test_group_result but not a submission' do
    test_group_result = create :test_group_result
    feedback_file = build :feedback_file_with_test_run, test_group_result: test_group_result
    expect(feedback_file).to be_valid
  end

  it 'is not valid when missing both submission and test_group_result association' do
    feedback_file = build :feedback_file, submission: nil
    expect(feedback_file).to_not be_valid
  end
end
