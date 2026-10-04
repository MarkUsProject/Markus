describe GenerateJob do
  let(:instructor) { create(:instructor) }
  let(:user) { instructor.user }
  let(:exam_template) { create(:exam_template_midterm) }

  let(:file) { file_fixture('scanned_exams/midterm1-v2-test.pdf') }

  context 'when running as a background job' do
    let(:job_args) { [exam_template, 2, 0] }

    it_behaves_like 'background job'
  end

  describe '#perform' do
    before do
      allow(CombinePDF).to(receive(:load).and_wrap_original { |m| m.call file })
    end

    it 'should create a new Prawn Document' do
      expect(Prawn::Document).to receive(:new).exactly(1).time.and_call_original
      GenerateJob.perform_now(exam_template, 1, 0, user)
    end

    it 'should create several Prawn Documents' do
      expect(Prawn::Document).to receive(:new).exactly(5).times.and_call_original
      GenerateJob.perform_now(exam_template, 5, 0, user)
    end

    it 'should create a QR code' do
      expect(RQRCode::QRCode).to receive(:new).exactly(exam_template.num_pages).times.and_call_original
      GenerateJob.perform_now(exam_template, 1, 0, user)
    end

    it 'should create a QR code with the correct content' do
      page_count = 0
      allow(RQRCode::QRCode).to receive(:new).and_wrap_original do |m, *args|
        expect(args[0]).to eq qr_content(page_count, exam_template, 0)
        page_count += 1
        m.call(*args)
      end
      GenerateJob.perform_now(exam_template, 1, 0, user)
    end

    it 'should create a QR code with correct content when there is a positive start value' do
      page_count = 0
      allow(RQRCode::QRCode).to receive(:new).and_wrap_original do |m, *args|
        expect(args[0]).to eq qr_content(page_count, exam_template, 3)
        page_count += 1
        m.call(*args)
      end
      GenerateJob.perform_now(exam_template, 1, 3, user)
    end

    it 'should create a QR code with correct content when there are multiple copies' do
      page_count = 0
      allow(RQRCode::QRCode).to receive(:new).and_wrap_original do |m, *args|
        expect(args[0]).to eq qr_content(page_count, exam_template, 0)
        page_count += 1
        m.call(*args)
      end
      GenerateJob.perform_now(exam_template, 2, 0, user)
    end

    it 'should create a QR code with correct content when there are multiple copies and a positive start value' do
      page_count = 0
      allow(RQRCode::QRCode).to receive(:new).and_wrap_original do |m, *args|
        expect(args[0]).to eq qr_content(page_count, exam_template, 2)
        page_count += 1
        m.call(*args)
      end
      GenerateJob.perform_now(exam_template, 2, 2, user)
    end

    it 'should save a file to disk' do
      GenerateJob.perform_now(exam_template, 1, 0, user)
      expect(File).to exist(File.join(exam_template.tmp_path,
                                      exam_template.generated_copies_file_name(1, 0)))
    end

    it 'should save the correct number of pages' do
      pdf_mock = CombinePDF.new
      expect(CombinePDF).to receive(:new).and_return(pdf_mock)

      GenerateJob.perform_now(exam_template, 3, 0, user)

      expect(pdf_mock.pages.length).to eq 18
    end
  end
end

def qr_content(page_count, exam_template, start)
  file_num = (page_count / exam_template.num_pages).floor + start
  page_num = (page_count % exam_template.num_pages) + 1
  "#{exam_template.name}-#{file_num}-#{page_num}"
end
