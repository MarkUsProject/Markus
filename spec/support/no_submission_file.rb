shared_examples 'No submission file' do
  describe 'When the student did not submit any files' do
    it 'should not deduct grace credits' do
      members = {}
      @grouping.accepted_student_memberships.each do |student_membership|
        members[student_membership.user.id] = student_membership.user.remaining_grace_credits
      end
      @rule.apply_submission_rule(@submission)
      @grouping.reload
      @grouping.accepted_student_memberships.each do |student_membership|
        expect(members[student_membership.user.id]).to eq(student_membership.user.remaining_grace_credits)
      end
    end
  end
end
