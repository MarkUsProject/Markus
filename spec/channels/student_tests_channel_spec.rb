require 'rails_helper'

describe StudentTestsChannel, type: :channel do
  context 'when the role is a student' do
    let!(:student) { create :student }
    let!(:current_user) { student.user }
    before do
      stub_connection(current_user: current_user)
    end
    context 'when the student can not run tests' do
      it 'should not establish a subscription' do
        subscribe course_id: student.course_id
        expect(subscription).to be_rejected
      end
    end
    context 'when the student can run tests' do
      let!(:assignment) do
        create :assignment, assignment_properties_attributes:
        { token_start_date: 1.hour.ago, enable_student_tests: true, tokens_per_period: 1 }
      end
      before do
        subscribe course_id: student.course_id, assignment_id: assignment.id
      end
      it 'should establish a subscription' do
        expect(subscription).to be_confirmed
      end
      it 'should stream from the correct user instance' do
        expect(subscription).to have_stream_for(current_user)
      end
    end
  end
  context 'when the role is not a student' do
    let!(:instructor) { create :instructor }
    let!(:current_user) { instructor.user }
    before do
      stub_connection(current_user: current_user)
    end
    context 'when the role is an instructor' do
      let!(:assignment) do
        create :assignment, assignment_properties_attributes:
        { token_start_date: 1.hour.ago, enable_student_tests: true, tokens_per_period: 1 }
      end
      it 'should not establish a subscription' do
        subscribe course_id: instructor.course_id, assignment_id: assignment.id
        expect(subscription).to be_rejected
      end
    end
    context 'when the user in conjunction with the course_id can not find a role' do
      context 'when course_id is nil' do
        it 'should not establish a subscription' do
          subscribe course_id: nil
          expect(subscription).to be_rejected
        end
      end
      context 'when course_id is not nil' do
        it 'should not establish a subscription' do
          subscribe course_id: -1
          expect(subscription).to be_rejected
        end
      end
    end
  end
end
