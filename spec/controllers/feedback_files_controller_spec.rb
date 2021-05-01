describe FeedbackFilesController do
  let(:grouping) { create(:grouping_with_inviter_and_submission) }
  let(:feedback_file) { create(:feedback_file, submission: grouping.submissions.first) }

  describe 'get_feedback_file' do
    let(:admin) { create(:admin) }

    context 'when an admin requests a feedback file' do
      it 'should download the file' do
        get_as admin, :get_feedback_file, params: {
          id: feedback_file.id,
          grouping_id: feedback_file.submission.grouping.id,
          assignment_id: feedback_file.submission.grouping.assignment.id
        }
        expect(response.body).to eq(feedback_file.file_content)
      end
    end

    context 'when a TA requests a feedback file' do
      let(:ta) { create(:ta) }

      it 'should download the file' do
        get_as ta, :get_feedback_file, params: {
          id: feedback_file.id,
          grouping_id: feedback_file.submission.grouping.id,
          assignment_id: feedback_file.submission.grouping.assignment.id
        }
        expect(response.body).to eq(feedback_file.file_content)
      end
    end

    context 'when a student requests their own feedback file' do
      it 'should download the file' do
        get_as feedback_file.submission.grouping.students.first, :get_feedback_file, params: {
          id: feedback_file.id,
          grouping_id: feedback_file.submission.grouping.id,
          assignment_id: feedback_file.submission.grouping.assignment.id
        }
        expect(response.body).to eq(feedback_file.file_content)
      end
    end

    context 'when a student requests a feedback file that is not their own' do
      it 'should not download the file' do
        @student = create(:student)
        get_as @student, :get_feedback_file, params: {
          id: feedback_file.id,
          grouping_id: feedback_file.submission.grouping.id,
          assignment_id: feedback_file.submission.grouping.assignment.id
        }
        expect(response.status).to eq(403)
        expect(response.body).to eq("")
      end
    end
  end
end
