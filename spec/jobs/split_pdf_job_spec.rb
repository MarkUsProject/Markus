# TODO: Fix these tests
xdescribe SplitPDFJob do
  context 'split PDF job' do
    before(:each) do
      admin = create(:admin)
      assignment = create(:assignment)
      file = File.open('db/data/scanned_exams/midterm1.pdf')
      @exam_template = ExamTemplate.create_with_file(file.read, assignment_id: assignment.id, filename: 'midterm1.pdf')
      FileUtils.rm_rf(@exam_template.base_path)
    end

    context 'Multiple exam template made up of different page numbers in randomized order' do
      before(:each) do
        path = 'db/data/scanned_exams/midterm46.pdf'
        @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
      end

      it 'have zero QR scan errors' do
        expect(@split_pdf_log.num_pages_qr_scan_error).to eq 0
      end

      it 'saves all the exam templates with page numbers that are error free in corresponding complete directory' do
        expect(Dir.entries(@exam_template.base_path + '/complete/6/').sort)
          .to eq %w[. .. 1.pdf 2.pdf 3.pdf 4.pdf 5.pdf 6.pdf 7.pdf 8.pdf].sort
        expect(Dir.entries(@exam_template.base_path + '/complete/7/').sort)
          .to eq %w[. .. 1.pdf 2.pdf 3.pdf 4.pdf 5.pdf 6.pdf 7.pdf 8.pdf].sort
        expect(Dir.entries(@exam_template.base_path + '/complete/8/').sort)
          .to eq %w[. .. 1.pdf 2.pdf 3.pdf 4.pdf 5.pdf 6.pdf 7.pdf 8.pdf].sort
      end
    end

    context 'error-free exam template' do
      before(:each) do
        path = 'db/data/scanned_exams/midterm27.pdf'
        @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
      end

      it 'have pdf of each page in complete directory (error-free)' do
        expect(Dir.entries(@exam_template.base_path + '/complete/27').sort)
          .to eq %w[. .. 1.pdf 2.pdf 3.pdf 4.pdf 5.pdf 6.pdf 7.pdf 8.pdf].sort
      end

      it 'have zero QR scan errors' do
        expect(@split_pdf_log.num_pages_qr_scan_error).to eq 0
      end
    end

    context 'made up of only 3 duplicate pages' do
      before(:each) do
        path = 'db/data/scanned_exams/midterm21.pdf'
        SplitPDFJob.perform_now(@exam_template, path)
      end

      it 'have 1 pdf in incomplete directory' do
        expect(Dir.entries(@exam_template.base_path + '/incomplete/21/').sort)
          .to eq %w[. .. 1.pdf].sort
      end

      it 'have 2 pdfs in error directory' do
        error_dir_entries = Dir.entries(File.join(@exam_template.base_path, 'error')) - %w[. ..]
        expect(error_dir_entries.length).to eq 2
      end
    end

    context 'missing page' do
      context 'missing one page: Page 2' do
        before(:each) do
          path = 'db/data/scanned_exams/midterm37.pdf'
          @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
        end

        it 'have zero QR scan error' do
          expect(@split_pdf_log.num_pages_qr_scan_error).to eq 0
        end

        it 'have pdf of every page except for 1 missing one in incomplete directory' do
          expect(Dir.entries(@exam_template.base_path + '/incomplete/37/').sort)
            .to eq %w[. .. 1.pdf 3.pdf 4.pdf 5.pdf 6.pdf 7.pdf 8.pdf].sort
        end
      end

      context 'missing multiple pages: Page 2 and Page 5' do
        before(:each) do
          path = 'db/data/scanned_exams/midterm25.pdf'
          @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
        end

        it 'have zero QR scan error' do
          expect(@split_pdf_log.num_pages_qr_scan_error).to eq 0
        end

        it 'have pdf of every page except for 2 missing ones in incomplete directory' do
          expect(Dir.entries(@exam_template.base_path + '/incomplete/25/').sort)
            .to eq %w[. .. 1.pdf 3.pdf 4.pdf 6.pdf 7.pdf 8.pdf].sort
        end
      end

      context 'missing every page except for the first page' do
        before(:each) do
          path = 'db/data/scanned_exams/midterm45.pdf'
          @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
        end

        it 'have zero QR scan error' do
          expect(@split_pdf_log.num_pages_qr_scan_error).to eq 0
        end

        it 'have pdf of the first page incomplete directory' do
          expect(Dir.entries(@exam_template.base_path + '/incomplete/45/').sort)
            .to eq %w[. .. 1.pdf].sort
        end
      end
    end

    context 'pages are upside down' do
      context 'all pages upside down' do
        before(:each) do
          path = 'db/data/scanned_exams/midterm26.pdf'
          @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
        end

        it 'have as many QR scan errors as number of pages' do
          expect(@split_pdf_log.num_pages_qr_scan_error).to eq @split_pdf_log.original_num_pages
        end

        it 'generate error in each page' do
          error_dir_entries = Dir.entries(File.join(@exam_template.base_path, 'error')) - %w[. ..]
          expect(error_dir_entries.length).to eq 8
        end
      end

      context 'page 2 and page 3 are upside down' do
        before(:each) do
          path = 'db/data/scanned_exams/midterm28.pdf'
          @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
        end

        it 'have 2 QR scan errors' do
          expect(@split_pdf_log.num_pages_qr_scan_error).to eq 2
        end

        it 'have pdf of each page in incomplete directory excluding page 2 and page 3' do
          expect(Dir.entries(@exam_template.base_path + '/incomplete/28/').sort)
            .to eq %w[. .. 1.pdf 4.pdf 5.pdf 6.pdf 7.pdf 8.pdf].sort
        end

        it 'have 2 pdfs in error directory' do
          error_dir_entries = Dir.entries(File.join(@exam_template.base_path, 'error')) - %w[. ..]
          expect(error_dir_entries.length).to eq 2
        end
      end
    end

    context 'shuffled pages' do
      before(:each) do
        path = 'db/data/scanned_exams/midterm29.pdf'
        @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
      end

      # midterm29.pdf is supposed to be error-free but it generated an error for a page
      it 'have one QR scan error' do
        expect(@split_pdf_log.num_pages_qr_scan_error).to eq 1
      end

      # midterm29.pdf is supposed to be in complete directory, but one page had an error
      it 'have pdf of each page in incomplete directory except for page 1' do
        expect(Dir.entries(@exam_template.base_path + '/incomplete/29/').sort)
          .to eq %w[. .. 2.pdf 3.pdf 4.pdf 5.pdf 6.pdf 7.pdf 8.pdf].sort
      end
    end

    context 'scratched out' do
      context 'scratched out QR code in one page: Page 3' do
        before(:each) do
          path = 'db/data/scanned_exams/midterm30.pdf'
          @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
        end

        it 'have one QR scan error' do
          expect(@split_pdf_log.num_pages_qr_scan_error).to eq 1
        end

        it 'have 1 pdf in error directory' do
          error_dir_entries = Dir.entries(File.join(@exam_template.base_path, 'error')) - %w[. ..]
          expect(error_dir_entries.length).to eq 1
        end
      end

      context 'scratched out QR code in multiple pages: Page 3 and Page 8' do
        before(:each) do
          path = 'db/data/scanned_exams/midterm33.pdf'
          @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
        end

        it 'have two QR scan errors' do
          expect(@split_pdf_log.num_pages_qr_scan_error).to eq 2
        end

        it 'have other pages that are error free in incomplete directory' do
          expect(Dir).to exist(@exam_template.base_path + '/incomplete/33/')
        end

        it 'have 2 pdfs in error directory' do
          error_dir_entries = Dir.entries(File.join(@exam_template.base_path, 'error')) - %w[. ..]
          expect(error_dir_entries.length).to eq 2
        end
      end
    end

    context 'shuffled pages and missing page 1 and page 5' do
      before(:each) do
        path = 'db/data/scanned_exams/midterm31.pdf'
        @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
      end

      it 'have zero QR scan error' do
        expect(@split_pdf_log.num_pages_qr_scan_error).to eq 0
      end

      it 'have pdf of every page except for 2 missing ones in incomplete directory' do
        expect(Dir.entries(@exam_template.base_path + '/incomplete/31/').sort)
          .to eq %w[. .. 2.pdf 3.pdf 4.pdf 6.pdf 7.pdf 8.pdf].sort
      end
    end

    context 'only Page 1 and Page 2 are present Page 2 is upside down' do
      before(:each) do
        path = 'db/data/scanned_exams/midterm34.pdf'
        @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
      end

      it 'have one QR scan error' do
        expect(@split_pdf_log.num_pages_qr_scan_error).to eq 1
      end

      it 'have Page 1 in incomplete directory' do
        expect(Dir.entries(@exam_template.base_path + '/incomplete/34/').sort)
          .to eq %w[. .. 1.pdf].sort
      end

      it 'have 1 pdf in error directory' do
        error_dir_entries = Dir.entries(File.join(@exam_template.base_path, 'error')) - %w[. ..]
        expect(error_dir_entries.length).to eq 1
      end
    end

    context 'Page 3 is upside down and QR code in Page 6 is scratched out' do
      before(:each) do
        path = 'db/data/scanned_exams/midterm35.pdf'
        @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
      end

      it 'have two QR scan errors' do
        expect(@split_pdf_log.num_pages_qr_scan_error).to eq 2
      end

      it 'have other pages that are error free in incomplete directory' do
        expect(Dir).to exist(@exam_template.base_path + '/incomplete/35/')
      end

      it 'have 2 pdfs in error directory' do
        error_dir_entries = Dir.entries(File.join(@exam_template.base_path, 'error')) - %w[. ..]
        expect(error_dir_entries.length).to eq 2
      end
    end

    context 'Page 1 and Page 2 are missing, QR code in Page 7 is scratched out, pages are shuffled' do
      before(:each) do
        path = 'db/data/scanned_exams/midterm36.pdf'
        @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
      end

      it 'have one QR scan error' do
        expect(@split_pdf_log.num_pages_qr_scan_error).to eq 1
      end

      it 'have other pages that are error free in incomplete directory' do
        expect(Dir.entries(@exam_template.base_path + '/incomplete/36/').sort)
          .to eq %w[. .. 3.pdf 4.pdf 5.pdf 6.pdf 8.pdf].sort
      end
    end

    context 'Page 3 and 5 are upside down, QR code in Page 1 and 2 is scratched out, pages are shuffled' do
      before(:each) do
        path = 'db/data/scanned_exams/midterm42.pdf'
        @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
      end

      it 'have four QR scan errors' do
        expect(@split_pdf_log.num_pages_qr_scan_error).to eq 4
      end

      it 'have other pages that are error free in incomplete directory' do
        expect(Dir.entries(@exam_template.base_path + '/incomplete/42/').sort)
          .to eq %w[. .. 4.pdf 6.pdf 7.pdf 8.pdf].sort
      end

      it 'have 4 pdfs in error directory' do
        error_dir_entries = Dir.entries(File.join(@exam_template.base_path, 'error')) - %w[. ..]
        expect(error_dir_entries.length).to eq 4
      end
    end
  end
end
