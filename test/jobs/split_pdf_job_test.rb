require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class SplitPDFJobTest < ActiveJob::TestCase
  context 'split PDF job' do
    setup do
      @assignment = Assignment.make()
      f = File.open('db/data/scanned_exams/midterm1.pdf')
      @exam_template = ExamTemplate.create_with_file(f.read, assignment_id: @assignment.id, filename: 'midterm1.pdf')
    end

    context 'made up of only 3 duplicate pages' do
      should 'have 1 pdf in incomplete directory' do
        path = 'db/data/scanned_exams/midterm21.pdf'
        SplitPDFJob.perform_now(@exam_template, path)
        assert_equal Dir.entries(@exam_template.base_path + '/incomplete/21/').sort, ['.', '..', '1.pdf'].sort
      end

      should 'have 1 pdf in error directory' do
        path = 'db/data/scanned_exams/midterm21.pdf'
        SplitPDFJob.perform_now(@exam_template, path)
        error_dir = Dir.entries(@exam_template.base_path + '/error')
        error_generated_files = ['midterm21-1.pdf']
        assert_empty error_generated_files-error_dir
      end
    end

    context 'missing page' do
      context 'missing one page: Page 2' do
        should 'have pdf of every page except for 1 missing one in incomplete directory' do
          path = 'db/data/scanned_exams/midterm37.pdf'
          SplitPDFJob.perform_now(@exam_template, path)
          assert_equal Dir.entries(@exam_template.base_path + '/incomplete/37/').sort,
                       ['.', '..', '1.pdf', '3.pdf', '4.pdf', '5.pdf', '6.pdf', '7.pdf', '8.pdf'].sort
        end
      end

      context 'missing multiple pages: Page 2 and Page 5' do
        should 'have pdf of every page except for 2 missing ones in incomplete directory' do
          path = 'db/data/scanned_exams/midterm25.pdf'
          SplitPDFJob.perform_now(@exam_template, path)
          assert_equal Dir.entries(@exam_template.base_path + '/incomplete/25/').sort,
                       ['.', '..', '1.pdf', '3.pdf', '4.pdf', '6.pdf', '7.pdf', '8.pdf'].sort
        end
      end

      context 'missing every page except for the first page' do
        should 'have pdf of the first page incomplete directory' do
          path = 'db/data/scanned_exams/midterm45.pdf'
          SplitPDFJob.perform_now(@exam_template, path)
          assert_equal Dir.entries(@exam_template.base_path + '/incomplete/45/').sort,
                       ['.', '..', '1.pdf'].sort
        end
      end
    end

    context 'all pages upside down' do
      should 'generate error in each page' do
        path = 'db/data/scanned_exams/midterm26.pdf'
        SplitPDFJob.perform_now(@exam_template, path)
        error_dir = Dir.entries(@exam_template.base_path + '/error')
        error_generated_files = ['midterm26-0.pdf', 'midterm26-1.pdf', 'midterm26-2.pdf','midterm26-3.pdf',
                                 'midterm26-4.pdf', 'midterm26-5.pdf', 'midterm26-6.pdf', 'midterm26-7.pdf'] # Page 1 ~ 8
        assert_empty error_generated_files-error_dir
      end
    end

    context 'error-free exam template' do
      should 'have pdf of each page in complete directory (error-free)' do
        path = 'db/data/scanned_exams/midterm27.pdf'
        SplitPDFJob.perform_now(@exam_template, path)
        assert_equal Dir.entries(@exam_template.base_path + '/complete/27/').sort,
                     ['.', '..', '1.pdf', '2.pdf', '3.pdf', '4.pdf', '5.pdf', '6.pdf', '7.pdf', '8.pdf'].sort
      end
    end

    context 'Page 2 and page 3 are upside down' do
      should 'have pdf of each page in incomplete directory excluding page 2 and page 3' do
        path = 'db/data/scanned_exams/midterm28.pdf'
        SplitPDFJob.perform_now(@exam_template, path)
        assert_equal Dir.entries(@exam_template.base_path + '/incomplete/28/').sort,
                     ['.', '..', '1.pdf', '4.pdf', '5.pdf', '6.pdf', '7.pdf', '8.pdf'].sort
      end

      should 'generate error in page 2 and page 3' do
        path = 'db/data/scanned_exams/midterm28.pdf'
        SplitPDFJob.perform_now(@exam_template, path)
        error_dir = Dir.entries(@exam_template.base_path + '/error')
        error_generated_files = ['midterm28-1.pdf', 'midterm28-2.pdf'] # Page 2 and Page 3
        assert_empty error_generated_files-error_dir
      end
    end

    context 'pages are shuffled' do
      should 'have pdf of each page in complete directory' do
        path = 'db/data/scanned_exams/midterm29.pdf'
        SplitPDFJob.perform_now(@exam_template, path)
        assert_equal Dir.entries(@exam_template.base_path + '/complete/29/').sort,
                     ['.', '..', '1.pdf', '2.pdf', '3.pdf', '4.pdf', '5.pdf', '6.pdf', '7.pdf', '8.pdf'].sort
      end
    end

    context 'scratched out' do
      context 'QR code in one page: Page 3' do
        should 'have Page 3 in error directory' do
          path = 'db/data/scanned_exams/midterm30.pdf'
          SplitPDFJob.perform_now(@exam_template, path)
          error_dir = Dir.entries(@exam_template.base_path + '/error')
          error_generated_files = ['midterm30-2.pdf'] # Page 3
          assert_empty error_generated_files-error_dir
        end
      end

      context 'QR code in multiple pages: Page 3 and Page 8' do
        should 'have Page 3 and Page 8 in error directory' do
          path = 'db/data/scanned_exams/midterm33.pdf'
          SplitPDFJob.perform_now(@exam_template, path)
          error_dir = Dir.entries(@exam_template.base_path + '/error')
          error_generated_files = ['midterm33-2.pdf', 'midterm33-7.pdf'] # Page 3 and Page 8
          assert_empty error_generated_files-error_dir
        end

        should 'have other pages that are error free in incomplete directory' do
          assert Dir.exists?(@exam_template.base_path + '/incomplete/33/')
        end
      end

      context 'label "Exam 39-1" in one page' do
        should 'have pdf of each page in complete directory (error-free)' do
          path = 'db/data/scanned_exams/midterm39.pdf'
          SplitPDFJob.perform_now(@exam_template, path)
          assert_equal Dir.entries(@exam_template.base_path + '/complete/39/').sort,
                       ['.', '..', '1.pdf', '2.pdf', '3.pdf', '4.pdf', '5.pdf', '6.pdf', '7.pdf', '8.pdf'].sort
        end
      end
    end

    context 'pages are shuffled and missing page 1 and page 5' do
      should 'have pdf of every page except for 2 missing ones in incomplete directory' do
        path = 'db/data/scanned_exams/midterm31.pdf'
        SplitPDFJob.perform_now(@exam_template, path)
        assert_equal Dir.entries(@exam_template.base_path + '/incomplete/31/').sort,
                     ['.', '..', '2.pdf', '3.pdf', '4.pdf', '6.pdf', '7.pdf', '8.pdf'].sort
      end
    end

    context 'only Page 1 and Page 2 are present Page 2 is upside down' do
      should 'have pdf of Page 2 in error directory' do
        path = 'db/data/scanned_exams/midterm34.pdf'
        SplitPDFJob.perform_now(@exam_template, path)
        error_dir = Dir.entries(@exam_template.base_path + '/error')
        error_generated_files = ['midterm34-1.pdf'] # Page 2
        assert_empty error_generated_files-error_dir
      end

      should 'have Page 1 in incomplete directory' do
        path = 'db/data/scanned_exams/midterm34.pdf'
        SplitPDFJob.perform_now(@exam_template, path)
        assert_equal Dir.entries(@exam_template.base_path + '/incomplete/34/').sort,
                     ['.', '..', '1.pdf'].sort
      end
    end

    context 'Page 3 is upside down and QR code in Page 6 is scratched out' do
      should 'have Page 3 and Page 6 in error directory' do
        path = 'db/data/scanned_exams/midterm35.pdf'
        SplitPDFJob.perform_now(@exam_template, path)
        error_dir = Dir.entries(@exam_template.base_path + '/error')
        error_generated_files = ['midterm35-2.pdf', 'midterm35-5.pdf'] # Page 3 and Page 6
        assert_empty error_generated_files-error_dir
      end

      should 'have other pages that are error free in incomplete directory' do
        assert Dir.exists?(@exam_template.base_path + '/incomplete/35/')
      end
    end

    context 'Page 1 and Page 2 are missing, QR code in Page 7 is scratched out, pages are shuffled' do
      should 'have other pages that are error free in incomplete directory' do
        path = 'db/data/scanned_exams/midterm36.pdf'
        SplitPDFJob.perform_now(@exam_template, path)
        assert_equal Dir.entries(@exam_template.base_path + '/incomplete/36/').sort,
                     ['.', '..', '3.pdf', '4.pdf', '5.pdf', '6.pdf', '8.pdf'].sort
      end
    end

    context 'Page 3 and 5 are upside down, QR code in Page 1 and 2 is scratched out, pages are shuffled' do
      should 'have other pages that are error free in incomplete directory' do
        path = 'db/data/scanned_exams/midterm42.pdf'
        SplitPDFJob.perform_now(@exam_template, path)
        assert_equal Dir.entries(@exam_template.base_path + '/incomplete/42/').sort,
                     ['.', '..', '4.pdf', '6.pdf', '7.pdf', '8.pdf'].sort
      end

      should 'have Page 1, 2, 3, 5 in error directory' do
        path = 'db/data/scanned_exams/midterm42.pdf'
        error_dir = Dir.entries(@exam_template.base_path + '/error')
        SplitPDFJob.perform_now(@exam_template, path)
        error_generated_files = ['midterm42-0.pdf', 'midterm42-1.pdf', 'midterm42-2.pdf', 'midterm42-4pdf'] # Page 3 and Page 8
        assert_empty error_generated_files-error_dir
      end
    end
  end
end
