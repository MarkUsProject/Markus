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

    describe '#edit' do
      it 'should respond with 200 with html format' do
        get_as user, :edit, format: 'html', params: { course_id: course.id, id: exam_template.id }
        expect(response.status).to eq 200
      end
      it 'should respond with 200 with js format' do
        get_as user, :edit, format: 'js', params: { course_id: course.id, id: exam_template.id }
        expect(response.status).to eq 200
      end
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

    describe '#split' do
      let(:pdf) { fixture_file_upload(File.join('scanned_exams', 'midterm1-v2-test.pdf'), 'application/pdf') }
      let(:invalid_pdf) { fixture_file_upload('empty_file', 'text/yaml') }

      context 'with valid parameters' do
        before do
          patch_as user, :split, params: { assignment_id: exam_template.assignment.id,
                                           course_id: course.id,
                                           exam_template_id: exam_template.id,
                                           pdf_to_split: pdf }
        end
        it 'should respond with 200' do
          expect(response.status).to eq 200
        end
        it 'should send no error message' do
          expect(flash[:error]).to be_nil
        end
      end

      context 'with no exam template' do
        before :each do
          patch_as user, :split, params: { assignment_id: exam_template.assignment.id,
                                           course_id: course.id }
        end
        it 'should respond with 400' do
          expect(response.status).to eq 400
        end
        it 'should send appropriate error message' do
          expect(flash[:error].map { |f| extract_text f })
            .to eq([I18n.t('exam_templates.upload_scans.search_failure')].map { |f| extract_text f })
        end
      end

      context 'with no uploaded pdf' do
        before :each do
          patch_as user, :split, params: { assignment_id: exam_template.assignment.id,
                                           course_id: course.id,
                                           exam_template_id: exam_template.id }
        end
        it 'should respond with 400' do
          expect(response.status).to eq 400
        end
        it 'should send appropriate error message' do
          expect(flash[:error].map { |f| extract_text f })
            .to eq([I18n.t('exam_templates.upload_scans.missing')].map { |f| extract_text f })
        end
      end

      context 'with incorrect file type' do
        before :each do
          patch_as user, :split, params: { assignment_id: exam_template.assignment.id,
                                           course_id: course.id,
                                           exam_template_id: exam_template.id,
                                           pdf_to_split: invalid_pdf }
        end
        it 'should respond with 400' do
          expect(response.status).to eq 400
        end
        it 'should send appropriate error message' do
          expect(flash[:error].map { |f| extract_text f })
            .to eq([I18n.t('exam_templates.upload_scans.invalid')].map { |f| extract_text f })
        end
      end
    end

    describe '#fix_error' do
      let(:split_pdf_log) { create(:split_pdf_log, exam_template: exam_template) }
      let(:split_page) { create(:split_page, split_pdf_log: split_pdf_log) }
      let(:split_page_id) { split_page.id }
      let(:copy_number) { 1 }
      let(:page_number) { 1 }

      before do
        filename = "#{split_page_id}.pdf"
        error_file = File.join(exam_template.base_path, 'error', filename)
        complete_page = File.join(exam_template.base_path, 'complete', copy_number.to_s, page_number.to_s)
        incomplete_page = File.join(exam_template.base_path, 'incomplete', copy_number.to_s, page_number.to_s)

        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(error_file).and_return(true)
        allow(File).to receive(:exist?).with(complete_page).and_return(false)
        allow(File).to receive(:exist?).with(incomplete_page).and_return(false)
        post_as user, :fix_error,
                params: { course_id: course.id,
                          id: exam_template.id,
                          commit: 'Save',
                          split_page_id: split_page_id,
                          copy_number: copy_number,
                          page_number: page_number }
      end

      context 'when the split page id does not exist' do
        let(:split_page_id) { -1 }

        it 'reports an error' do
          expect(flash[:error]).to_not be_empty
          expect(response.body).to eq("#{split_page_id}.pdf")
        end
      end

      context 'when the error page does not exist' do
        it 'reports an error', skip_before: true do
          post_as user, :fix_error,
                  params: { course_id: course.id,
                            id: exam_template.id,
                            commit: 'Save',
                            split_page_id: split_page_id,
                            copy_number: copy_number,
                            page_number: page_number }

          expect(flash[:error]).to_not be_empty
          expect(response.body).to eq("#{split_page_id}.pdf")
        end
      end

      context 'when the copy number is blank' do
        let(:copy_number) { nil }

        it 'reports an error' do
          expect(flash[:error]).to_not be_empty
          expect(response.body).to eq("#{split_page_id}.pdf")
        end
      end

      context 'when the copy number is not an int' do
        let(:copy_number) { 'not an int' }

        it 'reports an error' do
          expect(flash[:error]).to_not be_empty
          expect(response.body).to eq("#{split_page_id}.pdf")
        end
      end

      context 'when the copy number is invalid' do
        let(:copy_number) { -1 }

        it 'reports an error' do
          expect(flash[:error]).to_not be_empty
          expect(response.body).to eq("#{split_page_id}.pdf")
        end
      end

      context 'when the page number is blank' do
        let(:page_number) { nil }

        it 'reports an error' do
          expect(flash[:error]).to_not be_empty
          expect(response.body).to eq("#{split_page_id}.pdf")
        end
      end

      context 'when the page number is invalid' do
        let(:page_number) { 'not an int' }

        it 'reports an error' do
          expect(flash[:error]).to_not be_empty
          expect(response.body).to eq("#{split_page_id}.pdf")
        end
      end

      context 'when the page number exceeds the exam template page count' do
        let(:page_number) { exam_template.num_pages + 1 }

        it 'reports an error' do
          expect(flash[:error]).to_not be_empty
          expect(response.body).to eq("#{split_page_id}.pdf")
        end
      end
    end

    describe '#view_logs' do
      before { get_as user, :view_logs, params: { assignment_id: exam_template.assignment.id, course_id: course.id } }
      it('should respond with 200') { expect(response.status).to eq 200 }
    end

    describe '#download_generate' do
      context 'when the filename is invalid' do
        before do
          get_as user, :download_generate,
                 params: { assignment_id: exam_template.assignment.id, course_id: course.id, id: exam_template.id,
                           file_name: '../../a.pdf' }
        end

        it 'responds with an error status code' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe '#download_error_file' do
      context 'when the filename is invalid' do
        before do
          get_as user, :download_error_file,
                 params: { assignment_id: exam_template.assignment.id, course_id: course.id, id: exam_template.id,
                           file_name: '../../a.pdf' }
        end

        it 'responds with an error status code' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
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

      describe '#edit' do
        it 'should respond with 403 with html format' do
          get_as user, :edit, format: 'html', params: { course_id: course.id, id: exam_template.id }
          expect(response.status).to eq 403
        end
        it 'should respond with 403 with js format' do
          get_as user, :edit, format: 'js', params: { course_id: course.id, id: exam_template.id }
          expect(response.status).to eq 403
        end
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
