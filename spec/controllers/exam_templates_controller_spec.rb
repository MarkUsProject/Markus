describe ExamTemplatesController do
  # TODO: add 'role is from a different course' shared tests to each route test below
  let(:exam_template) { create(:exam_template_midterm) }
  let(:course) { exam_template.course }
  shared_examples 'An authorized instructor or grader managing exam templates' do
    describe '#index' do
      before { get_as user, :index, params: { course_id: course.id, assignment_id: exam_template.assignment.id } }
      it('should respond with 200') { expect(response.status).to eq 200 }
    end
    describe '#create' do
      let(:file_io) { fixture_file_upload('scanned_exams/midterm1-v2-test.pdf') }
      let(:params) do
        { create_template: { file_io: file_io, name: 'Template 1' },
          assignment_id: exam_template.assignment.id, course_id: course.id }
      end
      before { post_as user, :create, params: params }
      it('should respond with 302') { expect(response.status).to eq 302 }
    end

    describe '#update' do
      before { put_as user, :update, params: params }

      context 'when updating the exam template name' do
        let(:params) do
          { exam_template: { name: 'test-template' },
            id: exam_template.id, course_id: course.id }
        end

        it 'updates the exam template name' do
          expect(exam_template.reload.name).to eq 'test-template'
        end

        it 'responds with 302' do
          expect(response).to have_http_status 302
        end
      end

      context 'when replacing the exam template file with a PDF file' do
        let(:file_io) { fixture_file_upload('scanned_exams/midterm1-v2-test.pdf') }
        let(:params) do
          { exam_template: { new_template: file_io },
            id: exam_template.id, course_id: course.id }
        end

        it 'updates the exam template file' do
          expect(exam_template.reload.filename).to eq 'midterm1-v2-test.pdf'
        end

        it 'responds with 302' do
          expect(response).to have_http_status 302
        end
      end

      context 'when replacing the exam template file with a non-PDF file' do
        let(:file_io) { fixture_file_upload('page_white_text.png') }
        let(:params) do
          { exam_template: { new_template: file_io },
            id: exam_template.id, course_id: course.id }
        end
        let!(:original_filename) { exam_template.filename }

        it 'does not update the exam template file' do
          expect(exam_template.reload.filename).to eq original_filename
        end

        it 'displays a flash error message' do
          expect(flash[:error].map { |f| extract_text f }).to eq [I18n.t('exam_templates.update.failure')]
        end

        it 'responds with 302' do
          expect(response).to have_http_status 302
        end
      end
    end

    describe '#destroy' do
      before { delete_as user, :destroy, params: { id: exam_template.id, course_id: course.id } }
      it('should respond with 302') { expect(response.status).to eq 302 }
    end
    describe '#view_logs' do
      before { get_as user, :view_logs, params: { assignment_id: exam_template.assignment.id, course_id: course.id } }
      it('should respond with 200') { expect(response.status).to eq 200 }
    end
  end

  describe 'When the user is instructor' do
    let(:user) { create(:instructor) }
    include_examples 'An authorized instructor or grader managing exam templates'
  end

  describe 'When the user is grader' do
    context 'When grader is allowed to manage exam template' do
      let(:user) { create(:ta, manage_assessments: true) }
      include_examples 'An authorized instructor or grader managing exam templates'
    end
    context 'When grader is not allowed to manage exam template' do
      # By default all the grader permissions are set to false
      let(:user) { create(:ta) }
      describe '#index' do
        before { get_as user, :index, params: { assignment_id: exam_template.assignment.id, course_id: course.id } }
        it('should respond with 403') { expect(response.status).to eq 403 }
      end
      describe '#create' do
        let(:file_io) { fixture_file_upload('scanned_exams/midterm1-v2-test.pdf') }
        let(:params) do
          { create_template: { file_io: file_io, name: 'Template 1' },
            assignment_id: exam_template.assignment.id, course_id: course.id }
        end
        before { post_as user, :create, params: params }
        it('should respond with 403') { expect(response.status).to eq 403 }
      end
      describe '#update' do
        let(:params) do
          { exam_template: { name: 'template-1' },
            id: exam_template.id, course_id: course.id }
        end
        before { put_as user, :update, params: params }
        it('should respond with 403') { expect(response.status).to eq 403 }
      end
      describe '#destroy' do
        before do
          delete_as user, :destroy, params: { id: exam_template.id, course_id: course.id }
        end
        it('should respond with 403') { expect(response.status).to eq 403 }
      end
      describe '#view_logs' do
        before { get_as user, :view_logs, params: { assignment_id: exam_template.assignment.id, course_id: course.id } }
        it('should respond with 403') { expect(response.status).to eq 403 }
      end
    end
  end
end
