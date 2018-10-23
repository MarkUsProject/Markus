describe SubmissionFile do
  # Ensure that the the following relationship exists
  it { is_expected.to belong_to(:submission) }
  it { is_expected.to have_many(:annotations) }
  it { is_expected.to validate_presence_of :filename }
  it { is_expected.to validate_presence_of :path }

  context 'A .java Submission file' do
    before(:each) do
      @submission_file = SubmissionFile.create(filename: 'filename.java',
                                               path:     'path',
                                               submission_id: 1)
    end
    it 'return java' do
      expect(@submission_file.get_file_type).to eq('java')
    end
    it 'return java comment' do
      expect(@submission_file.get_comment_syntax).to eq(%w(/* */))
    end
  end

  context 'A .rb Submission file' do
    before(:each) do
      @submission_file = SubmissionFile.create(filename: 'filename.rb',
                                               path:     'path',
                                               submission_id: 1)
    end
    it 'return ruby' do
      expect(@submission_file.get_file_type).to eq('ruby')
    end
    it 'return ruby comment' do
      expect(@submission_file.get_comment_syntax).to eq(["=begin\n", "\n=end"])
    end
  end

  context 'A .py Submission file' do
    before(:each) do
      @submission_file = SubmissionFile.create(filename: 'filename.py',
                                               path:     'path',
                                               submission_id: 1)
    end
    it 'return python' do
      expect(@submission_file.get_file_type).to eq('python')
    end
    it 'return python comment' do
      expect(@submission_file.get_comment_syntax).to eq(%w(""" """))
    end
  end

  context 'A .js Submission file' do
    before(:each) do
      @submission_file = SubmissionFile.create(filename: 'filename.js',
                                               path:     'path',
                                               submission_id: 1)
    end
    it 'return javascript' do
      expect(@submission_file.get_file_type).to eq('javascript')
    end
    it 'return javascript comment' do
      expect(@submission_file.get_comment_syntax).to eq(%w(/* */))
    end
  end

  context 'A .c Submission file' do
    before(:each) do
      @submission_file = SubmissionFile.create(filename: 'filename.c',
                                               path:     'path',
                                               submission_id: 1)
    end
    it 'return c' do
      expect(@submission_file.get_file_type).to eq('c')
    end
    it 'return c comment' do
      expect(@submission_file.get_comment_syntax).to eq(%w(/* */))
    end
  end

  context 'A no extension Submission file' do
    before(:each) do
      @submission_file = SubmissionFile.create(filename: 'filename',
                                               path:     'path',
                                               submission_id: 1)
    end
    it 'return a unknown file extension' do
      expect(@submission_file.get_file_type).to eq('unknown')
    end
    it 'return generic comment' do
      expect(@submission_file.get_comment_syntax).to eq(%w(## ##))
    end
  end

  context 'An unknown Submission file' do
    before(:each) do
      @submission_file = SubmissionFile.create(filename: 'filename.toto',
                                               path:     'path',
                                               submission_id: 1)
    end
    it 'return a unknown file extension' do
      expect(@submission_file.get_file_type).to eq('unknown')
    end
    it 'return generic comment' do
      expect(@submission_file.get_comment_syntax).to eq(%w(## ##))
    end
  end

  context 'A supported image' do
    before(:each) do
      # currently supported formats: ['.jpeg', '.jpg', '.gif', '.png']
      @jpeg_file = SubmissionFile.create(filename: 'filename.jpeg',
                                        path:     'path',
                                        submission_id: 1)
      @jpg_file = SubmissionFile.create(filename: 'filename.jpg',
                                        path:     'path',
                                        submission_id: 2)
      @gif_file = SubmissionFile.create(filename: 'filename.gif',
                                       path:     'path',
                                       submission_id: 3)
      @png_file = SubmissionFile.create(filename: 'filename.png',
                                       path:     'path',
                                       submission_id: 4)
      @unsupported_file = SubmissionFile.create(filename: 'filename.bmp',
                                       path:     'path',
                                       submission_id: 5)
    end
    it 'return true' do
      expect(@jpeg_file.is_supported_image?).to be true
      expect(@jpg_file.is_supported_image?).to be true
      expect(@gif_file.is_supported_image?).to be true
      expect(@png_file.is_supported_image?).to be true
    end
    it 'return false' do
      expect(@unsupported_file.is_supported_image?).to be false
    end
  end

  context 'Calling the get_annotation_grid method' do
    context 'from a text file' do
      before(:each) do
        @submission_file = SubmissionFile.create(filename: 'filename',
                                                path: 'path')
      end
      it 'return nil' do
        expect(@submission_file.get_annotation_grid).to be nil
      end
    end

    context 'from an image file' do
      before(:each) do
        @submission_file = SubmissionFile.create(filename: 'filename.jpeg',
                                                path: 'path')
      end
      context 'with no annotations' do
        it 'return []' do
          expect(@submission_file.get_annotation_grid).to eq([])
        end
      end
      context 'with valid annotations' do
        before(:each) do
          @ta = Ta.new({user_name: 'exist_user',
                        first_name: 'Nelle',
                        last_name: 'Varoquaux'})
          @annot1 = ImageAnnotation.new({submission_file: @submission_file,
                                          x1: 0, x2: 10, y1: 0, y2: 10, id: 3,
                                          annotation_text: AnnotationText.new({id: 1}),
                                          creator: @ta})
          @annot2 = ImageAnnotation.new({submission_file: @submission_file,
                                          x1: 57, x2: 73, y1: 2, y2: 100, id: 4,
                                          annotation_text: AnnotationText.new({id: 2}),
                                          creator: @ta})
        end
        it 'return a corresponding array' do
          @submission_file.annotations.push(@annot1)
          @submission_file.annotations.push(@annot2)
          expect(@submission_file.get_annotation_grid.sort { |x,y| x[:id] <=> y[:id]})
            .to eq([{id: 1, annot_id: 3, x_range: {start: 0, end: 10},
                     y_range: {start: 0, end: 10}},
                    {id: 2, annot_id: 4, x_range: {start: 57, end: 73},
                     y_range: {start: 2, end: 100}}])
        end
      end
    end

    context 'from a pdf file' do
      before(:each) do
        @submission_file = SubmissionFile.create(filename: 'filename.jpeg',
                                                path: 'path')
      end
      context 'with no annotations' do
        it 'return []' do
          expect(@submission_file.get_annotation_grid).to eq([])
        end
      end
      context 'with valid annotations' do
        before(:each) do
          @ta = Ta.new({user_name: 'exist_user',
                        first_name: 'Nelle',
                        last_name: 'Varoquaux'})
          @annot1 = ImageAnnotation.new({submission_file: @submission_file,
                                          x1: 0, x2: 10, y1: 0, y2: 10, id: 3,
                                          annotation_text: AnnotationText.new({id: 1}),
                                          creator: @ta})
          @annot2 = ImageAnnotation.new({submission_file: @submission_file,
                                          x1: 57, x2: 73, y1: 2, y2: 100, id: 4,
                                          annotation_text: AnnotationText.new({id: 2}),
                                          creator: @ta})
        end
        it 'return a corresponding array' do
          @submission_file.annotations.push(@annot1)
          @submission_file.annotations.push(@annot2)
          expect(@submission_file.get_annotation_grid.sort { |x,y| x[:id] <=> y[:id]})
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
