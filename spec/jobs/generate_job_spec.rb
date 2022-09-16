describe GenerateJob do
  let(:instructor) { create(:instructor) }
  let(:exam_template) { create(:exam_template_midterm) }

  context 'when running as a background job' do
    let(:job_args) { [exam_template, 2, 0] }
    include_examples 'background job'
  end

  let(:file) { file_fixture('scanned_exams/midterm1-v2-test.pdf') }

  context 'when generating pdfs' do
    before :each do
      allow(CombinePDF).to(receive(:load).and_wrap_original { |m| m.call file })
      allow_any_instance_of(CombinePDF::PDF).to receive(:save)
    end

    it 'should create a new Prawn Document' do
      expect(Prawn::Document).to receive(:new).exactly(1).time.and_call_original
      GenerateJob.perform_now(exam_template, 1, 0)
    end

    it 'should create several Prawn Documents' do
      expect(Prawn::Document).to receive(:new).exactly(5).times.and_call_original
      GenerateJob.perform_now(exam_template, 5, 0)
    end

    it 'should create a QR code' do
      expect(RQRCode::QRCode).to receive(:new).exactly(exam_template.num_pages).times.and_call_original
      GenerateJob.perform_now(exam_template, 1, 0)
    end

    it 'should create a QR code with the correct content' do
      page_count = 0
      allow(RQRCode::QRCode).to receive(:new).and_wrap_original do |m, *args|
        expect(args[0]).to eq qr_content(page_count, exam_template, 0)
        page_count += 1
        m.call(*args)
      end
      GenerateJob.perform_now(exam_template, 1, 0)
    end

    it 'should create a QR code with correct content when there is a positive start value' do
      page_count = 0
      allow(RQRCode::QRCode).to receive(:new).and_wrap_original do |m, *args|
        expect(args[0]).to eq qr_content(page_count, exam_template, 3)
        page_count += 1
        m.call(*args)
      end
      GenerateJob.perform_now(exam_template, 1, 3)
    end

    it 'should create a QR code with correct content when there are multiple copies' do
      page_count = 0
      allow(RQRCode::QRCode).to receive(:new).and_wrap_original do |m, *args|
        expect(args[0]).to eq qr_content(page_count, exam_template, 0)
        page_count += 1
        m.call(*args)
      end
      GenerateJob.perform_now(exam_template, 2, 0)
    end

    it 'should create a QR code with correct content when there are multiple copies and a positive start value' do
      page_count = 0
      allow(RQRCode::QRCode).to receive(:new).and_wrap_original do |m, *args|
        expect(args[0]).to eq qr_content(page_count, exam_template, 2)
        page_count += 1
        m.call(*args)
      end
      GenerateJob.perform_now(exam_template, 2, 2)
    end

    it 'should save a file to disk' do
      expect_any_instance_of(CombinePDF::PDF).to receive(:save)
      GenerateJob.perform_now(exam_template, 1, 0)
    end

    it 'should save the correct number of pages' do
      expect_any_instance_of(CombinePDF::PDF).to receive(:save) do |pdf|
        expect(pdf.pages.length).to eq(3 * exam_template.num_pages)
      end
      GenerateJob.perform_now(exam_template, 3, 0)
    end
  end
end

def qr_content(page_count, exam_template, start)
  file_num = (page_count / exam_template.num_pages).floor + start
  page_num = (page_count % exam_template.num_pages) + 1
  "#{exam_template.name}-#{file_num}-#{page_num}"
end
