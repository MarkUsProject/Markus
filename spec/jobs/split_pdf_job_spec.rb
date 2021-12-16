describe SplitPdfJob do
  let(:instructor) { create(:instructor) }
  let(:exam_template) { create(:exam_template_midterm) }

  before(:each) do
    FileUtils.mkdir_p File.join(exam_template.base_path, 'raw')
    FileUtils.mkdir_p File.join(exam_template.base_path, 'error')
    FileUtils.rm_rf(File.join(exam_template.base_path, 'error'))
  end

  it 'correctly splits a PDF with 20 valid test papers, where all pages are in order' do
    filename = 'midterm_scan_1-20.pdf'
    split_pdf_log = exam_template.split_pdf_logs.create(
      filename: filename,
      original_num_pages: 120,
      num_groups_in_complete: 0,
      num_groups_in_incomplete: 0,
      num_pages_qr_scan_error: 0,
      role: instructor
    )
    FileUtils.cp "db/data/scanned_exams/#{filename}",
                 File.join(exam_template.base_path, 'raw', "raw_upload_#{split_pdf_log.id}.pdf")
    SplitPdfJob.perform_now(exam_template, '', split_pdf_log, filename, instructor)

    expect(Group.count).to eq 20
    expect(split_pdf_log.num_groups_in_complete + split_pdf_log.num_groups_in_incomplete).to eq 20

    # Ideally there would be no scan errors, but we'll use a higher tolerance here.
    expect(split_pdf_log.num_pages_qr_scan_error).to be <= 5
  end

  context 'when running as a background job' do
    let(:job_args) do
      split_pdf_log = exam_template.split_pdf_logs.create(filename: 'midterm_scan_1-20.pdf',
                                                          original_num_pages: 6,
                                                          num_groups_in_complete: 0,
                                                          num_groups_in_incomplete: 0,
                                                          num_pages_qr_scan_error: 0,
                                                          role: instructor)
      [exam_template, '', split_pdf_log, 'midterm_scan_100.pdf', instructor]
    end
    include_examples 'background job'
  end

  it 'correctly splits a PDF with one valid test paper with pages out of order' do
    filename = 'midterm_scan_100.pdf'
    split_pdf_log = exam_template.split_pdf_logs.create(
      filename: filename,
      original_num_pages: 6,
      num_groups_in_complete: 0,
      num_groups_in_incomplete: 0,
      num_pages_qr_scan_error: 0,
      role: instructor
    )
    FileUtils.cp "db/data/scanned_exams/#{filename}",
                 File.join(exam_template.base_path, 'raw', "raw_upload_#{split_pdf_log.id}.pdf")
    SplitPdfJob.perform_now(exam_template, '', split_pdf_log, filename, instructor)

    expect(Group.count).to eq 1
    expect(split_pdf_log.num_groups_in_complete).to eq 1
    expect(split_pdf_log.num_pages_qr_scan_error).to eq 0
    expect(split_pdf_log.split_pages.where(status: 'Saved to complete directory').count).to eq 6
  end

  it 'correctly splits a PDF with one test paper with two pages upside-down' do
    filename = 'midterm_scan_101.pdf'
    split_pdf_log = exam_template.split_pdf_logs.create(
      filename: filename,
      original_num_pages: 6,
      num_groups_in_complete: 0,
      num_groups_in_incomplete: 0,
      num_pages_qr_scan_error: 0,
      role: instructor
    )
    FileUtils.cp "db/data/scanned_exams/#{filename}",
                 File.join(exam_template.base_path, 'raw', "raw_upload_#{split_pdf_log.id}.pdf")
    SplitPdfJob.perform_now(exam_template, '', split_pdf_log, filename, instructor)

    expect(Group.count).to eq 1
    expect(split_pdf_log.num_groups_in_incomplete).to eq 1
    expect(split_pdf_log.num_pages_qr_scan_error).to eq 2
    expect(split_pdf_log.split_pages.where(status: 'ERROR: QR code not found').count).to eq 2
    expect(split_pdf_log.split_pages.where(status: 'Saved to incomplete directory').count).to eq 4

    # Check that error pages were saved correctly.
    error_dir_entries = Dir.entries(File.join(exam_template.base_path, 'error')) - %w[. ..]
    expect(error_dir_entries.length).to eq 2
  end

  it 'correctly splits a PDF with one test paper with three pages having an unparseable QR code' do
    filename = 'midterm_scan_102.pdf'
    split_pdf_log = exam_template.split_pdf_logs.create(
      filename: filename,
      original_num_pages: 6,
      num_groups_in_complete: 0,
      num_groups_in_incomplete: 0,
      num_pages_qr_scan_error: 0,
      role: instructor
    )
    FileUtils.cp "db/data/scanned_exams/#{filename}",
                 File.join(exam_template.base_path, 'raw', "raw_upload_#{split_pdf_log.id}.pdf")
    SplitPdfJob.perform_now(exam_template, '', split_pdf_log, filename, instructor)

    expect(Group.count).to eq 1
    expect(split_pdf_log.num_groups_in_incomplete).to eq 1
    expect(split_pdf_log.num_pages_qr_scan_error).to eq 3
    expect(split_pdf_log.split_pages.where(status: 'ERROR: QR code not found').count).to eq 3
    expect(split_pdf_log.split_pages.where(status: 'Saved to incomplete directory').count).to eq 3

    # Check that error pages were saved correctly.
    error_dir_entries = Dir.entries(File.join(exam_template.base_path, 'error')) - %w[. ..]
    expect(error_dir_entries.length).to eq 3
  end

  it 'correctly splits a PDF with one test paper with cover page having an unparseable QR code' do
    filename = 'midterm_scan_103.pdf'
    split_pdf_log = exam_template.split_pdf_logs.create(
      filename: filename,
      original_num_pages: 6,
      num_groups_in_complete: 0,
      num_groups_in_incomplete: 0,
      num_pages_qr_scan_error: 0,
      role: instructor
    )
    FileUtils.cp "db/data/scanned_exams/#{filename}",
                 File.join(exam_template.base_path, 'raw', "raw_upload_#{split_pdf_log.id}.pdf")
    SplitPdfJob.perform_now(exam_template, '', split_pdf_log, filename, instructor)

    expect(Group.count).to eq 1
    expect(split_pdf_log.num_groups_in_incomplete).to eq 1
    expect(split_pdf_log.num_pages_qr_scan_error).to eq 1
    expect(split_pdf_log.split_pages.where(status: 'ERROR: QR code not found').count).to eq 1
    expect(split_pdf_log.split_pages.where(status: 'Saved to incomplete directory').count).to eq 5

    # Check that error pages were saved correctly.
    error_dir_entries = Dir.entries(File.join(exam_template.base_path, 'error')) - %w[. ..]
    expect(error_dir_entries.length).to eq 1
  end

  context 'when automatic parsing is enabled' do
    let(:exam_template) { create(:exam_template_with_automatic_parsing) }

    it 'correctly parses a student number and assigns the paper to that student' do
      create(:student, id_number: '0123456789')
      filename = 'test-auto-parse-scan-success.pdf'
      split_pdf_log = exam_template.split_pdf_logs.create(
        filename: filename,
        original_num_pages: 6,
        num_groups_in_complete: 0,
        num_groups_in_incomplete: 0,
        num_pages_qr_scan_error: 0,
        user: admin
      )
      FileUtils.cp "db/data/scanned_exams/#{filename}",
                   File.join(exam_template.base_path, 'raw', "raw_upload_#{split_pdf_log.id}.pdf")
      SplitPdfJob.perform_now(exam_template, '', split_pdf_log, filename, admin)

      group = Group.find_by(group_name: 'test-auto-parse_paper_1')
      expect(group).to_not be_nil
      grouping = group.groupings.find_by(assessment_id: exam_template.assessment_id)
      expect(grouping).to_not be_nil

      expect(grouping.accepted_students.size).to eq 1
      expect(grouping.accepted_students.first.id_number).to eq '0123456789'
    end

    it 'creates a group with no members when no text is parsed' do
      create(:student, id_number: '0123456789')
      filename = 'test-auto-parse-scan-blank.pdf'
      split_pdf_log = exam_template.split_pdf_logs.create(
        filename: filename,
        original_num_pages: 6,
        num_groups_in_complete: 0,
        num_groups_in_incomplete: 0,
        num_pages_qr_scan_error: 0,
        user: admin
      )
      FileUtils.cp "db/data/scanned_exams/#{filename}",
                   File.join(exam_template.base_path, 'raw', "raw_upload_#{split_pdf_log.id}.pdf")
      SplitPdfJob.perform_now(exam_template, '', split_pdf_log, filename, admin)

      group = Group.find_by(group_name: 'test-auto-parse_paper_3')
      expect(group).to_not be_nil
      grouping = group.groupings.find_by(assessment_id: exam_template.assessment_id)
      expect(grouping).to_not be_nil

      expect(grouping.accepted_students.size).to eq 0
    end
  end
end
