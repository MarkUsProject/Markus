require 'spec_helper'

describe SubmissionFile do
  # Ensure that the the following relationship exists
  context 'An existing SubmissionFile' do
    it { is_expected.to belong_to(:submission) }
    it { is_expected.to have_many(:annotations) }
    it { is_expected.to validate_presence_of :submission }
    it { is_expected.to validate_presence_of :filename }
    it { is_expected.to validate_presence_of :path }
  end

  context 'A SubmissionFile' do

    context 'A SubmissionFile without parameter and without id' do
      before(:each) do
        @submissionfile = SubmissionFile.create()
      end
      it 'be invalid and should not be saved' do
        expect(@submissionfile).not_to be_valid
        expect(@submissionfile.save).to be false
      end
    end

    context 'A SubmissionFile without parameter and with id' do
      before(:each) do
        @submissionfile = SubmissionFile.create()
        @submissionfile.submission_id = 1
      end
      it 'be invalid and should not be saved' do
        expect(@submissionfile).not_to be_valid
        expect(@submissionfile.save).to be false
      end
    end

    context 'A SubmissionFile without filename' do
      before(:each) do
        @submissionfile = SubmissionFile.create(filename: '',
                                                path:     'path')
        @submissionfile.submission_id = 1
      end

      it 'be invalid and should not be saved' do
        expect(@submissionfile).not_to be_valid
        expect(@submissionfile.save).to be false
      end
    end

    context 'A SubmissionFile without path' do
      before(:each) do
        @submissionfile = SubmissionFile.create(filename: 'filename',
                                                path:     '')
        @submissionfile.submission_id = 1
      end

      it 'be invalid and should not be saved' do
        expect(@submissionfile).not_to be_valid
        expect(@submissionfile.save).to be false
      end
    end

    context 'A SubmissionFile with filename and path, but without id' do
      before(:each) do
        @submissionfile = SubmissionFile.create(filename: 'filename',
                                                path:     'path')
      end

      it 'be invalid and should not be saved' do
        expect(@submissionfile).not_to be_valid
        expect(@submissionfile.save).to be false
      end
    end

    context 'A .java Submission file' do
      before(:each) do
        @submissionfile = SubmissionFile.create(filename: 'filename.java',
                                                path:     'path')
        @submissionfile.submission_id = 1
      end
      it 'return java' do
        expect(@submissionfile.get_file_type).to eq('java')
      end
      it 'return java comment' do
        expect(@submissionfile.get_comment_syntax).to eq(%w(/* */))
      end
    end

    context 'A .rb Submission file' do
      before(:each) do
        @submissionfile = SubmissionFile.create(filename: 'filename.rb',
                                                path:     'path')
        @submissionfile.submission_id = 1
      end

      it 'return ruby' do
        expect(@submissionfile.get_file_type).to eq('ruby')
      end
      it 'return ruby comment' do
        expect(@submissionfile.get_comment_syntax).to eq(["=begin\n", "\n=end"])
      end
    end

    context 'A .py Submission file' do
      before(:each) do
        @submissionfile = SubmissionFile.create(filename: 'filename.py',
                                                path:     'path')
        @submissionfile.submission_id = 1
      end

      it 'return python' do
        expect(@submissionfile.get_file_type).to eq('python')
      end
      it 'return python comment' do
        expect(@submissionfile.get_comment_syntax).to eq(%w(""" """))
      end
    end

    context 'A .js Submission file' do
      before(:each) do
        @submissionfile = SubmissionFile.create(filename: 'filename.js',
                                                path:     'path')
        @submissionfile.submission_id = 1
      end

      it 'return javascript' do
        expect(@submissionfile.get_file_type).to eq('javascript')
      end
      it 'return javascript comment' do
        expect(@submissionfile.get_comment_syntax).to eq(%w(/* */))
      end
    end

    context 'A .c Submission file' do

      before(:each) do
        @submissionfile = SubmissionFile.create(filename: 'filename.c',
                                                path:     'path')
        @submissionfile.submission_id = 1
      end

      it 'return c' do
        expect(@submissionfile.get_file_type).to eq('c')
      end
      it 'return c comment' do
        expect(@submissionfile.get_comment_syntax).to eq(%w(/* */))
      end
    end

    context 'A no extension Submission file' do
      before(:each) do
        @submissionfile = SubmissionFile.create(filename: 'filename',
                                                path:     'path')
        @submissionfile.submission_id = 1
      end

      it 'return a unknown file extension' do
        expect(@submissionfile.get_file_type).to eq('unknown')
      end
      it 'return generic comment' do
        expect(@submissionfile.get_comment_syntax).to eq(%w(## ##))
      end
    end

    context 'An unknown Submission file' do
      before(:each) do
        @submissionfile = SubmissionFile.create(filename: 'filename.toto',
                                                path:     'path')
        @submissionfile.submission_id = 1
      end

      it 'return a unknown file extension' do
        expect(@submissionfile.get_file_type).to eq('unknown')
      end
      it 'return generic comment' do
        expect(@submissionfile.get_comment_syntax).to eq(%w(## ##))
      end
    end

    context 'A supported image' do
      before(:each) do
        # currently supported formats: ['.jpeg', '.jpg', '.gif', '.png']
        @jpegfile = SubmissionFile.create(filename: 'filename.jpeg',
                                          path:     'path',
                                          submission_id: 1)
        @jpgfile = SubmissionFile.create(filename: 'filename.jpg',
                                          path:     'path',
                                          submission_id: 2)
        @giffile = SubmissionFile.create(filename: 'filename.gif',
                                         path:     'path',
                                         submission_id: 3)
        @pngfile = SubmissionFile.create(filename: 'filename.png',
                                         path:     'path',
                                         submission_id: 4)
        @unsupportedfile = SubmissionFile.create(filename: 'filename.bmp',
                                         path:     'path',
                                         submission_id: 5)
      end

      it 'return true' do
        expect(@jpegfile.is_supported_image?).to be true
        expect(@jpgfile.is_supported_image?).to be true
        expect(@giffile.is_supported_image?).to be true
        expect(@pngfile.is_supported_image?).to be true
      end
      it 'return false' do
        expect(@unsupportedfile.is_supported_image?).to be false
      end
    end



    context 'Calling the get_annotation_grid method' do
      context 'from a text file' do
        before(:each) do
          @submissionfile = SubmissionFile.create(filename: 'filename',
                                                  path: 'path')
        end
        it 'return nil' do
          expect(@submissionfile.get_annotation_grid).to be nil
        end
      end

      context 'from an image file' do
        before(:each) do
          @submissionfile = SubmissionFile.create(filename: 'filename.jpeg',
                                                  path: 'path')
        end

        context 'with no annotations' do
          it 'return []' do
            expect(@submissionfile.get_annotation_grid).to eq([])
          end
        end

        context 'with valid annotations' do
          before(:each) do
            @ta = Ta.new({user_name: 'exist_user',
                          first_name: 'Nelle',
                          last_name: 'Varoquaux'})
            @annot1 = ImageAnnotation.new({submission_file: @submissionfile,
                                            x1: 0, x2: 10, y1: 0, y2: 10, id: 3,
                                            annotation_text: AnnotationText.new({id: 1}),
                                            creator: @ta})
            @annot2 = ImageAnnotation.new({submission_file: @submissionfile,
                                            x1: 57, x2: 73, y1: 2, y2: 100, id: 4,
                                            annotation_text: AnnotationText.new({id: 2}),
                                            creator: @ta})
          end
          it 'return a corresponding array' do
            @submissionfile.annotations.push(@annot1)
            @submissionfile.annotations.push(@annot2)
            expect(@submissionfile.get_annotation_grid.sort { |x,y| x[:id] <=> y[:id]})
              .to eq([{id: 1, annot_id: 3, x_range: {start: 0, end: 10},
                       y_range: {start: 0, end: 10}},
                      {id: 2, annot_id: 4, x_range: {start: 57, end: 73},
                       y_range: {start: 2, end: 100}}])
          end
        end
      end

      context 'from a pdf file' do
        before(:each) do
          @submissionfile = SubmissionFile.create(filename: 'filename.jpeg',
                                                  path: 'path')
        end
        context 'with no annotations' do
          it 'return []' do
            expect(@submissionfile.get_annotation_grid).to eq([])
          end
        end
        context 'with valid annotations' do
          before(:each) do
            @ta = Ta.new({user_name: 'exist_user',
                          first_name: 'Nelle',
                          last_name: 'Varoquaux'})
            @annot1 = ImageAnnotation.new({submission_file: @submissionfile,
                                            x1: 0, x2: 10, y1: 0, y2: 10, id: 3,
                                            annotation_text: AnnotationText.new({id: 1}),
                                            creator: @ta})
            @annot2 = ImageAnnotation.new({submission_file: @submissionfile,
                                            x1: 57, x2: 73, y1: 2, y2: 100, id: 4,
                                            annotation_text: AnnotationText.new({id: 2}),
                                            creator: @ta})
          end
          it 'return a corresponding array' do
            @submissionfile.annotations.push(@annot1)
            @submissionfile.annotations.push(@annot2)
            expect(@submissionfile.get_annotation_grid.sort { |x,y| x[:id] <=> y[:id]})
              .to eq([{id: 1, annot_id: 3, x_range: {start: 0, end: 10},
                       y_range: {start: 0, end: 10}},
                      {id: 2, annot_id: 4, x_range: {start: 57, end: 73},
                       y_range: {start: 2, end: 100}}])
          end
        end
      end
    end

    context 'A binary content' do
      it 'return true' do
        expect(SubmissionFile.is_binary?('���� JFIF  ` `  �� C 		')).to be true
      end
    end

    context 'A non binary content' do
      it 'return false' do
        expect(SubmissionFile.is_binary?('Non binary content')).to be false
      end
    end

    def teardown
      destroy_repos
    end
  end
end
