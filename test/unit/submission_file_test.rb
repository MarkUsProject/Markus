# encoding: utf-8
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

require 'shoulda'

 class SubmissionFileTest < ActiveSupport::TestCase

  # Ensure that the the following relationship exists
  context 'An existing SubmissionFile' do
    should belong_to :submission
    should have_many :annotations

    should validate_presence_of :submission
    should validate_presence_of :filename
    should validate_presence_of :path
  end

  context 'A SubmissionFile without parameter and without id' do
    setup do
      @submissionfile = SubmissionFile.new
    end

    should 'be invalid and should not be saved' do
      assert !@submissionfile.valid?
      assert !@submissionfile.save
    end
  end

  context 'A SubmissionFile without parameter' do
    setup do
      @submissionfile = SubmissionFile.new
      @submissionfile.submission_id = 1
    end

    should 'be invalid and should not be saved' do
      assert !@submissionfile.valid?
      assert !@submissionfile.save
    end
  end

  context 'A SubmissionFile without filename' do
    setup do
      @submissionfile = SubmissionFile.new(filename: '',
                                           path:     'path')
      @submissionfile.submission_id = 1
    end

    should 'be invalid and should not be saved' do
      assert !@submissionfile.valid?
      assert !@submissionfile.save
    end
  end

  context 'A SubmissionFile without path' do
    setup do
      @submissionfile = SubmissionFile.new(filename: 'filaname',
                                           path:     '')
      @submissionfile.submission_id = 1
    end

    should 'be invalid and should not be saved' do
      assert !@submissionfile.valid?
      assert !@submissionfile.save
    end
  end

  context 'A SubmissionFile with filename and path, but without id' do
    setup do
      @submissionfile = SubmissionFile.new(filename: 'filaname',
                                           path:     'path')
    end

    should 'be invalid and should not be saved' do
      assert !@submissionfile.valid?
      assert !@submissionfile.save
    end
  end

  context 'A .java Submission file' do
    setup do
      @submissionfile = SubmissionFile.new(filename: 'filename.java',
                                           path:     'path')
      @submissionfile.submission_id = 1
    end

    should 'return java' do
      assert_equal('java', @submissionfile.get_file_type)
    end
    should 'return java comment' do
      assert_equal(%w(/* */), @submissionfile.get_comment_syntax)
    end
  end

  context 'A .rb Submission file' do
    setup do
      @submissionfile = SubmissionFile.new(filename: 'filename.rb',
                                           path:     'path')
      @submissionfile.submission_id = 1
    end

    should 'return ruby' do
      assert_equal('ruby', @submissionfile.get_file_type)
    end
    should 'return ruby comment' do
      assert_equal(["=begin\n", "\n=end"], @submissionfile.get_comment_syntax)
    end
  end

  context 'A .py Submission file' do
    setup do
      @submissionfile = SubmissionFile.new(filename: 'filename.py',
                                           path:     'path')
      @submissionfile.submission_id = 1
    end

    should 'return python' do
      assert_equal('python', @submissionfile.get_file_type)
    end
    should 'return python comment' do
      assert_equal(%w(""" """), @submissionfile.get_comment_syntax)
    end
  end

  context 'A .js Submission file' do
    setup do
      @submissionfile = SubmissionFile.new(filename: 'filename.js',
                                           path:     'path')
      @submissionfile.submission_id = 1
    end

    should 'return javascript' do
      assert_equal('javascript', @submissionfile.get_file_type)
    end
    should 'return javascript comment' do
      assert_equal(%w(/* */), @submissionfile.get_comment_syntax)
    end
  end

  context 'A .c Submission file' do
    setup do
      @submissionfile = SubmissionFile.new(filename: 'filename.c',
                                           path:     'path')
      @submissionfile.submission_id = 1
    end

    should 'return c' do
      assert_equal('c', @submissionfile.get_file_type)
    end
    should 'return c comment' do
      assert_equal(%w(/* */), @submissionfile.get_comment_syntax)
    end
  end

  context 'A no extension Submission file' do
    setup do
      @submissionfile = SubmissionFile.new(filename: 'filename',
                                           path:     'path')
      @submissionfile.submission_id = 1
    end

    should 'return a unknown file extension' do
      assert_equal('unknown', @submissionfile.get_file_type)
    end
    should 'return generic comment' do
      assert_equal(%w(## ##), @submissionfile.get_comment_syntax)
    end
  end

  context 'An unknown Submission file' do
    setup do
      @submissionfile = SubmissionFile.new(filename: 'filename.toto',
                                           path:     'path')
      @submissionfile.submission_id = 1
    end

    should 'return a unknown file extension' do
      assert_equal('unknown', @submissionfile.get_file_type)
    end
    should 'return generic comment' do
      assert_equal(%w(## ##), @submissionfile.get_comment_syntax)
    end
  end

  context 'A supported image' do
    setup do
      # currently supported formats: ['.jpeg', '.jpg', '.gif', '.png']
      @jpegfile = SubmissionFile.new(filename: 'filename.jpeg', path: 'path')
      @jpegfile.submission_id = 1

      @jpgfile = SubmissionFile.new(filename: 'filename.jpg', path: 'path')
      @jpgfile.submission_id = 2

      @giffile = SubmissionFile.new(filename: 'filename.gif', path: 'path')
      @giffile.submission_id = 3

      @pngfile = SubmissionFile.new(filename: 'filename.png', path: 'path')
      @pngfile.submission_id = 4

      @unsupportedfile = SubmissionFile.new(filename: 'filename.bmp', path: 'path')
      @unsupportedfile.submission_id = 5
    end

    should 'return true' do
      assert @jpegfile.is_supported_image?
      assert @jpgfile.is_supported_image?
      assert @giffile.is_supported_image?
      assert @pngfile.is_supported_image?
    end
    should 'return false' do
      assert !@unsupportedfile.is_supported_image?
    end
  end


  context 'Calling the get_annotation_grid method' do
    context 'from a text file' do
      setup do
        @submissionfile = SubmissionFile.make(filename: 'filename',
          path: 'path')
      end
      should 'Return nil' do
        assert_nil @submissionfile.get_annotation_grid
      end
    end

    context 'from an image file' do
      setup do
        @submissionfile = SubmissionFile.make(filename: 'filename.jpeg',
          path: 'path')
      end
      context 'with no annotations' do
        should 'return []' do
          assert_equal [], @submissionfile.get_annotation_grid
        end
      end
      context 'with valid annotations' do
        setup do
          @ta = Ta.make
          @annot1 = ImageAnnotation.make({submission_file: @submissionfile,
            x1: 0, x2: 10, y1: 0, y2: 10, id: 3,
            annotation_text: AnnotationText.make({id: 1}),
            creator: @ta})
          @annot2 = ImageAnnotation.make({submission_file: @submissionfile,
            x1: 57, x2: 73, y1: 2, y2: 100, id: 4,
            annotation_text: AnnotationText.make({id: 2}),
            creator: @ta})
        end
        should 'return a corresponding array' do
          @submissionfile.annotations.push(@annot1)
          @submissionfile.annotations.push(@annot2)
          assert_equal [{id: 1, annot_id: 3, x_range: {start: 0, end: 10},
              y_range: {start: 0, end: 10}},
            {id: 2, annot_id: 4, x_range: {start: 57, end: 73},
              y_range: {start: 2, end: 100}}],
            @submissionfile.get_annotation_grid.sort { |x,y| x[:id] <=> y[:id]}
        end
      end
    end

    context 'from a pdf file' do
      setup do
        @submissionfile = SubmissionFile.make(filename: 'filename.jpeg',
                                              path:     'path')
      end
      context 'with no annotations' do
        should 'return []' do
          assert_equal [], @submissionfile.get_annotation_grid
        end
      end
      context 'with valid annotations' do
        setup do
          @ta = Ta.make
          @annot1 = ImageAnnotation.make({submission_file: @submissionfile,
            x1: 0, x2: 10, y1: 0, y2: 10, id: 3,
            annotation_text: AnnotationText.make({id: 1}),
            creator: @ta})
          @annot2 = ImageAnnotation.make({submission_file: @submissionfile,
            x1: 57, x2: 73, y1: 2, y2: 100, id: 4,
            annotation_text: AnnotationText.make({id: 2}),
            creator: @ta})
        end
        should 'return a corresponding array' do
          @submissionfile.annotations.push(@annot1)
          @submissionfile.annotations.push(@annot2)
          assert_equal [{id: 1, annot_id: 3, x_range: {start: 0, end: 10},
              y_range: {start: 0, end: 10}},
            {id: 2, annot_id: 4, x_range: {start: 57, end: 73},
              y_range: {start: 2, end: 100}}],
            @submissionfile.get_annotation_grid.sort { |x,y| x[:id] <=> y[:id]}
        end
      end
    end
  end

  context 'A binary content' do

    should 'return true' do
      assert SubmissionFile.is_binary?('���� JFIF  ` `  �� C 		')
    end
  end

  context 'A non binary content' do

    should 'return false' do
      assert !SubmissionFile.is_binary?('Non binary content')
    end
  end


  def teardown
    destroy_repos
  end
end
