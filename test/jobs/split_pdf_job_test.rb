require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class SplitPDFJobTest < ActiveJob::TestCase
  context 'split PDF job' do
    setup do
      Admin.make
      assignment = Assignment.make(short_identifier: 'mdt')
      file = File.open('db/data/scanned_exams/midterm1.pdf')
      @exam_template = ExamTemplate.create_with_file(file.read, assignment_id: assignment.id, filename: 'midterm1.pdf')
      FileUtils.rm_rf(@exam_template.base_path)
    end

    context 'Multiple exam template made up of different page numbers in randomized order' do
      setup do
        path = 'db/data/scanned_exams/midterm46.pdf'
        @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
      end

      should 'have zero QR scan errors' do
        assert_equal @split_pdf_log.num_pages_qr_scan_error, 0
      end

      should 'saves all the exam templates with page numbers that are error free in corresponding complete directory' do
        assert_equal Dir.entries(@exam_template.base_path + '/complete/27/').sort,
                     %w[. .. 1.pdf 2.pdf 3.pdf 4.pdf 5.pdf 6.pdf 7.pdf 8.pdf].sort
        assert_equal Dir.entries(@exam_template.base_path + '/complete/29/').sort,
                     %w[. .. 1.pdf 2.pdf 3.pdf 4.pdf 5.pdf 6.pdf 7.pdf 8.pdf].sort
        assert_equal Dir.entries(@exam_template.base_path + '/complete/44/').sort,
                     %w[. .. 1.pdf 2.pdf 3.pdf 4.pdf 5.pdf 6.pdf 7.pdf 8.pdf].sort
      end
    end

    context 'error-free exam template' do
      setup do
        path = 'db/data/scanned_exams/midterm27.pdf'
        @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
      end

      should 'have pdf of each page in complete directory (error-free)' do
        assert_equal Dir.entries(@exam_template.base_path + '/complete/27/').sort,
                     %w[. .. 1.pdf 2.pdf 3.pdf 4.pdf 5.pdf 6.pdf 7.pdf 8.pdf].sort
      end

      should 'have zero QR scan errors' do
        assert_equal @split_pdf_log.num_pages_qr_scan_error, 0
      end
    end

    context 'made up of only 3 duplicate pages' do
      setup do
        path = 'db/data/scanned_exams/midterm21.pdf'
        SplitPDFJob.perform_now(@exam_template, path)
      end

      should 'have 1 pdf in incomplete directory' do
        assert_equal Dir.entries(@exam_template.base_path + '/incomplete/21/').sort, %w[. .. 1.pdf].sort
      end

      should 'have 2 pdfs in error directory' do
        error_dir_entries = Dir.entries(File.join(@exam_template.base_path, 'error')) - %w[. ..]
        assert_equal error_dir_entries.length, 2
      end
    end

    context 'missing page' do
      context 'missing one page: Page 2' do
        setup do
          path = 'db/data/scanned_exams/midterm37.pdf'
          @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
        end

        should 'have zero QR scan error' do
          assert_equal @split_pdf_log.num_pages_qr_scan_error, 0
        end

        should 'have pdf of every page except for 1 missing one in incomplete directory' do
          assert_equal Dir.entries(@exam_template.base_path + '/incomplete/37/').sort,
                       %w[. .. 1.pdf 3.pdf 4.pdf 5.pdf 6.pdf 7.pdf 8.pdf].sort
        end
      end

      context 'missing multiple pages: Page 2 and Page 5' do
        setup do
          path = 'db/data/scanned_exams/midterm25.pdf'
          @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
        end

        should 'have zero QR scan error' do
          assert_equal @split_pdf_log.num_pages_qr_scan_error, 0
        end

        should 'have pdf of every page except for 2 missing ones in incomplete directory' do
          assert_equal Dir.entries(@exam_template.base_path + '/incomplete/25/').sort,
                       %w[. .. 1.pdf 3.pdf 4.pdf 6.pdf 7.pdf 8.pdf].sort
        end
      end

      context 'missing every page except for the first page' do
        setup do
          path = 'db/data/scanned_exams/midterm45.pdf'
          @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
        end

        should 'have zero QR scan error' do
          assert_equal @split_pdf_log.num_pages_qr_scan_error, 0
        end

        should 'have pdf of the first page incomplete directory' do
          assert_equal Dir.entries(@exam_template.base_path + '/incomplete/45/').sort,
                       %w[. .. 1.pdf].sort
        end
      end
    end

    context 'pages are upside down' do
      context 'all pages upside down' do
        setup do
          path = 'db/data/scanned_exams/midterm26.pdf'
          @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
        end

        should 'have as many QR scan errors as number of pages' do
          assert_equal @split_pdf_log.num_pages_qr_scan_error, @split_pdf_log.original_num_pages
        end

        should 'generate error in each page' do
          error_dir_entries = Dir.entries(File.join(@exam_template.base_path, 'error')) - %w[. ..]
          assert_equal error_dir_entries.length, 8
        end
      end

      context 'page 2 and page 3 are upside down' do
        setup do
          path = 'db/data/scanned_exams/midterm28.pdf'
          @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
        end

        should 'have 2 QR scan errors' do
          assert_equal @split_pdf_log.num_pages_qr_scan_error, 2
        end

        should 'have pdf of each page in incomplete directory excluding page 2 and page 3' do
          assert_equal Dir.entries(@exam_template.base_path + '/incomplete/28/').sort,
                       %w[. .. 1.pdf 4.pdf 5.pdf 6.pdf 7.pdf 8.pdf].sort
        end

        should 'have 2 pdfs in error directory' do
          error_dir_entries = Dir.entries(File.join(@exam_template.base_path, 'error')) - %w[. ..]
          assert_equal error_dir_entries.length, 2
        end
      end
    end

    context 'shuffled pages' do
      setup do
        path = 'db/data/scanned_exams/midterm29.pdf'
        @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
      end

      should 'have zero QR scan errors' do
        assert_equal @split_pdf_log.num_pages_qr_scan_error, 0
      end

      should 'have pdf of each page in complete directory' do
        assert_equal Dir.entries(@exam_template.base_path + '/complete/29/').sort,
                     %w[. .. 1.pdf 2.pdf 3.pdf 4.pdf 5.pdf 6.pdf 7.pdf 8.pdf].sort
      end
    end

    context 'scratched out' do
      context 'scratched out QR code in one page: Page 3' do
        setup do
          path = 'db/data/scanned_exams/midterm30.pdf'
          @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
        end

        should 'have at least one QR scan error' do
          assert @split_pdf_log.num_pages_qr_scan_error >= 1
        end

        should 'have 3 pdfs in error directory' do
          error_dir_entries = Dir.entries(File.join(@exam_template.base_path, 'error')) - %w[. ..]
          assert_equal error_dir_entries.length, 2
        end
      end

      context 'scratched out QR code in multiple pages: Page 3 and Page 8' do
        setup do
          path = 'db/data/scanned_exams/midterm33.pdf'
          @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
        end

        should 'have at least two QR scan errors' do
          assert @split_pdf_log.num_pages_qr_scan_error >= 2
        end

        should 'have other pages that are error free in incomplete directory' do
          assert Dir.exists?(@exam_template.base_path + '/incomplete/33/')
        end

        should 'have 2 pdfs in error directory' do
          error_dir_entries = Dir.entries(File.join(@exam_template.base_path, 'error')) - %w[. ..]
          assert_equal error_dir_entries.length, 2
        end
      end
    end

    context 'shuffled pages and missing page 1 and page 5' do
      setup do
        path = 'db/data/scanned_exams/midterm31.pdf'
        @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
      end

      should 'have zero QR scan error' do
        assert_equal @split_pdf_log.num_pages_qr_scan_error, 0
      end

      should 'have pdf of every page except for 2 missing ones in incomplete directory' do
        assert_equal Dir.entries(@exam_template.base_path + '/incomplete/31/').sort,
                     %w[. .. 2.pdf 3.pdf 4.pdf 6.pdf 7.pdf 8.pdf].sort
      end
    end

    context 'only Page 1 and Page 2 are present Page 2 is upside down' do
      setup do
        path = 'db/data/scanned_exams/midterm34.pdf'
        @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
      end

      should 'have at least one QR scan error' do
        assert @split_pdf_log.num_pages_qr_scan_error >= 1
      end

      should 'have Page 1 in incomplete directory' do
        assert_equal Dir.entries(@exam_template.base_path + '/incomplete/34/').sort,
                     %w[. .. 1.pdf].sort
      end

      should 'have 1 pdf in error directory' do
        error_dir_entries = Dir.entries(File.join(@exam_template.base_path, 'error')) - %w[. ..]
        assert_equal error_dir_entries.length, 1
      end
    end

    context 'Page 3 is upside down and QR code in Page 6 is scratched out' do
      setup do
        path = 'db/data/scanned_exams/midterm35.pdf'
        @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
      end

      should 'have at least two QR scan errors' do
        assert @split_pdf_log.num_pages_qr_scan_error >= 2
      end

      should 'have other pages that are error free in incomplete directory' do
        assert Dir.exists?(@exam_template.base_path + '/incomplete/35/')
      end

      should 'have 3 pdfs in error directory' do
        error_dir_entries = Dir.entries(File.join(@exam_template.base_path, 'error')) - %w[. ..]
        assert_equal error_dir_entries.length, 3
      end
    end

    context 'Page 1 and Page 2 are missing, QR code in Page 7 is scratched out, pages are shuffled' do
      setup do
        path = 'db/data/scanned_exams/midterm36.pdf'
        @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
      end

      should 'have at least one QR scan error' do
        assert @split_pdf_log.num_pages_qr_scan_error >= 1
      end

      should 'have other pages that are error free in incomplete directory' do
        assert_equal Dir.entries(@exam_template.base_path + '/incomplete/36/').sort,
                     %w[. .. 3.pdf 4.pdf 5.pdf 6.pdf 8.pdf].sort
      end
    end

    context 'Page 3 and 5 are upside down, QR code in Page 1 and 2 is scratched out, pages are shuffled' do
      setup do
        path = 'db/data/scanned_exams/midterm42.pdf'
        @split_pdf_log = SplitPDFJob.perform_now(@exam_template, path)
      end

      should 'have at least four QR scan errors' do
        assert @split_pdf_log.num_pages_qr_scan_error >= 4
      end

      should 'have other pages that are error free in incomplete directory' do
        assert_equal Dir.entries(@exam_template.base_path + '/incomplete/42/').sort,
                     %w[. .. 4.pdf 6.pdf 7.pdf 8.pdf].sort
      end

      should 'have 4 pdfs in error directory' do
        error_dir_entries = Dir.entries(File.join(@exam_template.base_path, 'error')) - %w[. ..]
        assert_equal error_dir_entries.length, 4
      end
    end
  end
end
