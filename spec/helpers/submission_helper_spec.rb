describe SubmissionsHelper do
  describe '#get_file_info' do
    let(:assignment) { create(:assignment) }
    let(:grouping) { create(:grouping_with_inviter_and_submission, assignment: assignment) }
    let(:file_name) { 'test.zip' }
    let(:revision_identifier) { grouping.current_submission_used.revision_identifier }
    let(:helpers) { ActionController::Base.helpers }
    let(:file_obj) do
      Repository::RevisionFile.new(
        revision_identifier,
        name: file_name,
        path: grouping.assignment.repository_folder,
        mime_type: 'application/zip',
        last_modified_date: Time.current,
        submitted_date: Time.current
      )
    end

    it 'should generate and return the file url with correct assignment id' do
      file_info = get_file_info('test.zip', file_obj, assignment.course.id,
                                assignment.id, revision_identifier, '', grouping.id)
      expect(file_info[:url].match(%r{/assignments/(\d*)/})[1]).to eq(assignment.id.to_s)
    end
  end
end
