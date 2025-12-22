describe AutoMatchJob do
  let(:instructor) { create(:instructor) }
  let(:user) { instructor.user }
  let(:exam_template) { create(:exam_template_midterm) }

  before do
    FileUtils.mkdir_p File.join(exam_template.base_path, 'raw')
    FileUtils.mkdir_p File.join(exam_template.base_path, 'error')
  end

  context 'when automatic parsing is enabled' do
    subject do
      create(:student, id_number: '0123456789')
      FileUtils.cp "db/data/scanned_exams/#{filename}",
                   File.join(exam_template.base_path, 'raw', "raw_upload_#{split_pdf_log.id}.pdf")
      SplitPdfJob.perform_now(exam_template, '', split_pdf_log, filename, instructor, user)
      AutoMatchJob.perform_now([grouping], exam_template)
    end

    let(:exam_template) { create(:exam_template_with_automatic_parsing) }
    let(:split_pdf_log) do
      exam_template.split_pdf_logs.create(
        filename: filename,
        original_num_pages: 6,
        num_groups_in_complete: 0,
        num_groups_in_incomplete: 0,
        num_pages_qr_scan_error: 0,
        role: instructor
      )
    end

    let(:group) { Group.find_by(group_name: group_name) }
    let(:grouping) { group.groupings.find_by(assessment_id: exam_template.assessment_id) }

    context 'when scanner dependencies are installed',
            skip: Rails.application.config.scanner_enabled ? false : 'scanner dependencies not installed' do
      before { subject }

      context 'when there is a student number' do
        let(:filename) { 'test-auto-parse-scan-success.pdf' }
        let(:group_name) { 'test-auto-parse_paper_1' }

        it 'assigns the paper to the correct student in the correct group' do
          expect(grouping.accepted_students.first.id_number).to eq '0123456789'
        end

        it 'stores OCR match data in Redis with matched status' do
          ocr_data = OcrMatchService.get_match(grouping.id)
          expect(ocr_data).not_to be_nil
          expect(ocr_data[:parsed_value]).to eq '0123456789'
          expect(ocr_data[:field_type]).to eq 'id_number'
          expect(ocr_data[:matched]).to be true
          expect(ocr_data[:matched_student_id]).to eq grouping.accepted_students.first.id
        end

        it 'does not add matched grouping to unmatched set' do
          redis = Redis::Namespace.new(Rails.root.to_s, redis: Resque.redis)
          unmatched_set = redis.smembers('ocr_matches:unmatched')
          expect(unmatched_set).not_to include(grouping.id.to_s)
        end
      end

      context 'when there is no text to parse' do
        let(:filename) { 'test-auto-parse-scan-blank.pdf' }
        let(:group_name) { 'test-auto-parse_paper_3' }

        it 'does not assign a student to that group' do
          expect(grouping.accepted_students.size).to eq 0
        end

        it 'stores OCR match data with parsed value "None"' do
          ocr_data = OcrMatchService.get_match(grouping.id)
          # OCR returns "None" for blank scans
          expect(ocr_data).not_to be_nil
          expect(ocr_data[:parsed_value]).to eq 'None'
          expect(ocr_data[:matched]).to be false
        end
      end

      context 'when OCR parsing succeeds but no student match found' do
        # Use a different PDF file to avoid conflict with parent context's student creation
        # Override the subject to not create a student
        subject do
          FileUtils.cp "db/data/scanned_exams/#{filename}",
                       File.join(exam_template.base_path, 'raw', "raw_upload_#{split_pdf_log.id}.pdf")
          SplitPdfJob.perform_now(exam_template, '', split_pdf_log, filename, instructor, user)
          AutoMatchJob.perform_now([grouping], exam_template)
        end

        let(:filename) { 'test-auto-parse-scan-success.pdf' }
        let(:group_name) { 'test-auto-parse_paper_1' }

        it 'does not assign a student to the group' do
          expect(grouping.accepted_students.size).to eq 0
        end

        it 'stores OCR match data in Redis with unmatched status' do
          ocr_data = OcrMatchService.get_match(grouping.id)
          expect(ocr_data).not_to be_nil
          expect(ocr_data[:parsed_value]).to eq '0123456789'
          expect(ocr_data[:field_type]).to eq 'id_number'
          expect(ocr_data[:matched]).to be false
          expect(ocr_data[:matched_student_id]).to be_nil
        end

        it 'adds unmatched grouping to unmatched set' do
          redis = Redis::Namespace.new(Rails.root.to_s, redis: Resque.redis)
          unmatched_set = redis.smembers('ocr_matches:unmatched')
          expect(unmatched_set).to include(grouping.id.to_s)
        end
      end
    end

    context 'when the scanner dependencies are not installed' do
      before do
        allow(Rails.application.config).to receive(:scanner_enabled).and_return(false)
        subject
      end

      context 'when there is a student number' do
        let(:filename) { 'test-auto-parse-scan-success.pdf' }
        let(:group_name) { 'test-auto-parse_paper_1' }

        it 'does not assign a student to that group' do
          expect(grouping.accepted_students.size).to eq 0
        end
      end
    end
  end
end
