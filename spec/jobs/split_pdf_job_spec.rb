describe SplitPdfJob do
  let(:instructor) { create(:instructor) }
  let(:user) { instructor.user }
  let(:exam_template) { create(:exam_template_midterm) }

  before do
    FileUtils.mkdir_p File.join(exam_template.base_path, 'raw')
    FileUtils.mkdir_p File.join(exam_template.base_path, 'error')
    FileUtils.rm_rf(File.join(exam_template.base_path, 'error'))
    FileUtils.rm_rf(File.join(exam_template.base_path, 'complete'))
    FileUtils.rm_rf(File.join(exam_template.base_path, 'incomplete'))
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
    SplitPdfJob.perform_now(exam_template, '', split_pdf_log, filename, instructor, user)

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

    it_behaves_like 'background job'
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
    SplitPdfJob.perform_now(exam_template, '', split_pdf_log, filename, instructor, user)

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
    SplitPdfJob.perform_now(exam_template, '', split_pdf_log, filename, instructor, user)

    expect(Group.count).to eq 1
    expect(split_pdf_log.num_groups_in_complete).to eq 1
    expect(split_pdf_log.num_pages_qr_scan_error).to eq 0
    expect(split_pdf_log.split_pages.where(status: 'Saved to complete directory').count).to eq 6
  end

  it 'correctly splits a PDF with one test paper with three pages having an unparseable QR code but parseable text' do
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
    SplitPdfJob.perform_now(exam_template, '', split_pdf_log, filename, instructor, user)

    expect(Group.count).to eq 1
    expect(split_pdf_log.num_groups_in_complete).to eq 1
    expect(split_pdf_log.num_pages_qr_scan_error).to eq 0
    expect(split_pdf_log.split_pages.where(status: 'Saved to complete directory').count).to eq 6
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
    SplitPdfJob.perform_now(exam_template, '', split_pdf_log, filename, instructor, user)

    expect(Group.count).to eq 1
    expect(split_pdf_log.num_groups_in_incomplete).to eq 1
    expect(split_pdf_log.num_pages_qr_scan_error).to eq 1
    expect(split_pdf_log.split_pages.where(status: 'ERROR: QR code not found').count).to eq 1
    expect(split_pdf_log.split_pages.where(status: 'Saved to incomplete directory').count).to eq 5

    # Check that error pages were saved correctly.
    error_dir_entries = Dir.entries(File.join(exam_template.base_path, 'error')) - %w[. ..]
    expect(error_dir_entries.length).to eq 1
  end

  context 'when there are duplicated pages' do
    let(:filename) { 'midterm_scan_102.pdf' }
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
    let(:split_pdf_log2) do
      exam_template.split_pdf_logs.create(
        filename: filename,
        original_num_pages: 6,
        num_groups_in_complete: 0,
        num_groups_in_incomplete: 0,
        num_pages_qr_scan_error: 0,
        role: instructor
      )
    end

    before do
      FileUtils.cp "db/data/scanned_exams/#{filename}",
                   File.join(exam_template.base_path, 'raw', "raw_upload_#{split_pdf_log.id}.pdf")
      SplitPdfJob.perform_now(exam_template, '', split_pdf_log, filename, instructor, user)
    end

    context 'and on_duplicate = "error"' do
      it 'marks duplicated pages as errors' do
        FileUtils.cp "db/data/scanned_exams/#{filename}",
                     File.join(exam_template.base_path, 'raw', "raw_upload_#{split_pdf_log2.id}.pdf")
        SplitPdfJob.perform_now(exam_template, '', split_pdf_log2, filename, instructor, 'error', user)

        expect(split_pdf_log2.split_pages.where('status LIKE ?', '%already exists').size).to eq 6
        error_dir_entries = Dir.entries(File.join(exam_template.base_path, 'error')) - %w[. ..]
        expect(error_dir_entries.length).to eq 6
      end
    end

    context 'and on_duplicate = "overwrite"' do
      it 'overwrites existing pages' do
        FileUtils.cp "db/data/scanned_exams/#{filename}",
                     File.join(exam_template.base_path, 'raw', "raw_upload_#{split_pdf_log2.id}.pdf")
        SplitPdfJob.perform_now(exam_template, '', split_pdf_log2, filename, instructor, 'overwrite', user)

        expect(split_pdf_log2.split_pages.where('status LIKE ?', '%Overwritten%').size).to eq 6
        error_dir_entries = Dir.entries(File.join(exam_template.base_path, 'error')) - %w[. ..]
        expect(error_dir_entries.length).to eq 0
      end
    end

    context 'and on_duplicate = "ignore"' do
      it 'ignores duplicated pages' do
        FileUtils.cp "db/data/scanned_exams/#{filename}",
                     File.join(exam_template.base_path, 'raw', "raw_upload_#{split_pdf_log2.id}.pdf")
        SplitPdfJob.perform_now(exam_template, '', split_pdf_log2, filename, instructor, 'ignore', user)

        expect(split_pdf_log2.split_pages.where(status: 'Duplicate page ignored').size).to eq 6
        error_dir_entries = Dir.entries(File.join(exam_template.base_path, 'error')) - %w[. ..]
        expect(error_dir_entries.length).to eq 0
      end
    end
  end

  context 'when an uploaded test is missing pages, including the cover page' do
    # File contains pages 2, 4, 6
    # Template division: Q1: 3-3, Q2: 4-4, Q3: 5-6
    let(:group) { Group.find_by(group_name: 'midterm1-v2-test_paper_104') }
    let(:grouping) { exam_template.assignment.groupings.find_by(group_id: group.id) }

    before do
      filename = 'midterm_scan_104_evens.pdf'
      split_pdf_log = exam_template.split_pdf_logs.create(
        filename: filename,
        original_num_pages: 3,
        num_groups_in_complete: 0,
        num_groups_in_incomplete: 0,
        num_pages_qr_scan_error: 0,
        role: instructor
      )
      FileUtils.cp "db/data/scanned_exams/#{filename}",
                   File.join(exam_template.base_path, 'raw', "raw_upload_#{split_pdf_log.id}.pdf")
      SplitPdfJob.perform_now(exam_template, '', split_pdf_log, filename, instructor, user)
    end

    it 'creates a blank COVER.pdf' do
      grouping.access_repo do |repo|
        revision = repo.get_latest_revision
        cover_pdf_raw = repo.download_as_string(
          revision.files_at_path(exam_template.assignment.repository_folder)['COVER.pdf']
        )
        cover_pdf = CombinePDF.parse(cover_pdf_raw)
        expect(cover_pdf.pages.size).to eq 0
      end
    end

    it 'creates partial template division pdfs' do
      grouping.access_repo do |repo|
        revision = repo.get_latest_revision
        expected_pages = { 'Q1.pdf' => 0, 'Q2.pdf' => 1, 'Q3.pdf' => 1 }
        files = revision.files_at_path(exam_template.assignment.repository_folder)
        expected_pages.each do |filename, expected_page_num|
          expect(files.key?(filename)).to be true
          pdf_raw = repo.download_as_string(
            revision.files_at_path(exam_template.assignment.repository_folder)[filename]
          )
          pdf = CombinePDF.parse(pdf_raw)
          expect(pdf.pages.size).to eq expected_page_num
        end
      end
    end

    it 'creates a complete EXTRA.pdf' do
      grouping.access_repo do |repo|
        revision = repo.get_latest_revision
        pdf_raw = repo.download_as_string(
          revision.files_at_path(exam_template.assignment.repository_folder)['EXTRA.pdf']
        )
        pdf = CombinePDF.parse(pdf_raw)
        expect(pdf.pages.size).to eq 1
      end
    end
  end

  context 'when an uploaded test has pages in two different files' do
    # Files contains pages [1, 3, 5] and [2, 4, 6]
    # Template division: Q1: 3-3, Q2: 4-4, Q3: 5-6
    let(:group) { Group.find_by(group_name: 'midterm1-v2-test_paper_104') }
    let(:grouping) { exam_template.assignment.groupings.find_by(group_id: group.id) }

    before do
      filename = 'midterm_scan_104_evens.pdf'
      split_pdf_log1 = exam_template.split_pdf_logs.create(
        filename: filename,
        original_num_pages: 3,
        num_groups_in_complete: 0,
        num_groups_in_incomplete: 0,
        num_pages_qr_scan_error: 0,
        role: instructor
      )
      FileUtils.cp "db/data/scanned_exams/#{filename}",
                   File.join(exam_template.base_path, 'raw', "raw_upload_#{split_pdf_log1.id}.pdf")
      SplitPdfJob.perform_now(exam_template, '', split_pdf_log1, filename, instructor, user)

      filename = 'midterm_scan_104_odds.pdf'
      split_pdf_log2 = exam_template.split_pdf_logs.create(
        filename: filename,
        original_num_pages: 3,
        num_groups_in_complete: 0,
        num_groups_in_incomplete: 0,
        num_pages_qr_scan_error: 0,
        role: instructor
      )
      FileUtils.cp "db/data/scanned_exams/#{filename}",
                   File.join(exam_template.base_path, 'raw', "raw_upload_#{split_pdf_log2.id}.pdf")
      SplitPdfJob.perform_now(exam_template, '', split_pdf_log2, filename, instructor, user)
    end

    it 'creates a complete COVER.pdf' do
      grouping.access_repo do |repo|
        revision = repo.get_latest_revision
        cover_pdf_raw = repo.download_as_string(
          revision.files_at_path(exam_template.assignment.repository_folder)['COVER.pdf']
        )
        cover_pdf = CombinePDF.parse(cover_pdf_raw)
        expect(cover_pdf.pages.size).to eq 1
      end
    end

    it 'creates complete template division pdfs' do
      grouping.access_repo do |repo|
        revision = repo.get_latest_revision
        expected_pages = { 'Q1.pdf' => 1, 'Q2.pdf' => 1, 'Q3.pdf' => 2 }
        files = revision.files_at_path(exam_template.assignment.repository_folder)
        expected_pages.each do |filename, expected_page_num|
          expect(files.key?(filename)).to be true
          pdf_raw = repo.download_as_string(
            revision.files_at_path(exam_template.assignment.repository_folder)[filename]
          )
          pdf = CombinePDF.parse(pdf_raw)
          expect(pdf.pages.size).to eq expected_page_num
        end
      end
    end

    it 'creates a complete EXTRA.pdf' do
      grouping.access_repo do |repo|
        revision = repo.get_latest_revision
        pdf_raw = repo.download_as_string(
          revision.files_at_path(exam_template.assignment.repository_folder)['EXTRA.pdf']
        )
        pdf = CombinePDF.parse(pdf_raw)
        expect(pdf.pages.size).to eq 1
      end
    end
  end

  it 'creates a new grouping to assign the paper to' do
    filename = 'test-auto-parse-scan-success.pdf'
    group_name = 'test-auto-parse_paper_1'
    exam_template = create(:exam_template_with_automatic_parsing)
    split_pdf_log = exam_template.split_pdf_logs.create(
      filename: filename,
      original_num_pages: 6,
      num_groups_in_complete: 0,
      num_groups_in_incomplete: 0,
      num_pages_qr_scan_error: 0,
      role: instructor
    )

    FileUtils.mkdir_p File.join(exam_template.base_path, 'raw')
    FileUtils.cp "db/data/scanned_exams/#{filename}",
                 File.join(exam_template.base_path, 'raw', "raw_upload_#{split_pdf_log.id}.pdf")
    SplitPdfJob.perform_now(exam_template, '', split_pdf_log, filename, instructor, user)
    group = Group.find_by(group_name: group_name)
    grouping = group.groupings.find_by(assessment_id: exam_template.assessment_id)
    expect(grouping).not_to be_nil
  end
end
