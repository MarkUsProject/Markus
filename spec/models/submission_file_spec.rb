describe SubmissionFile do
  # Ensure that the the following relationship exists
  it { is_expected.to belong_to(:submission) }
  it { is_expected.to have_many(:annotations) }
  it { is_expected.to validate_presence_of :filename }
  it { is_expected.to validate_presence_of :path }
  it { is_expected.to have_one(:course) }

  context 'A .java Submission file' do
    before(:each) do
      @submission_file = SubmissionFile.create(filename: 'filename.java',
                                               path: 'path',
                                               submission_id: 1)
    end
    it 'return java' do
      expect(FileHelper.get_file_type(@submission_file.filename)).to eq('java')
    end
    it 'return java comment' do
      expect(FileHelper.get_comment_syntax(@submission_file.filename)).to eq(%w[/* */])
    end
  end

  context 'A .rb Submission file' do
    before(:each) do
      @submission_file = SubmissionFile.create(filename: 'filename.rb',
                                               path: 'path',
                                               submission_id: 1)
    end
    it 'return ruby' do
      expect(FileHelper.get_file_type(@submission_file.filename)).to eq('ruby')
    end
    it 'return ruby comment' do
      expect(FileHelper.get_comment_syntax(@submission_file.filename)).to eq(%W[=begin\n \n=end])
    end
  end

  context 'A .py Submission file' do
    before(:each) do
      @submission_file = SubmissionFile.create(filename: 'filename.py',
                                               path: 'path',
                                               submission_id: 1)
    end
    it 'return python' do
      expect(FileHelper.get_file_type(@submission_file.filename)).to eq('python')
    end
    it 'return python comment' do
      expect(FileHelper.get_comment_syntax(@submission_file.filename)).to eq(%w[""" """])
    end
  end

  context 'A .js Submission file' do
    before(:each) do
      @submission_file = SubmissionFile.create(filename: 'filename.js',
                                               path: 'path',
                                               submission_id: 1)
    end
    it 'return javascript' do
      expect(FileHelper.get_file_type(@submission_file.filename)).to eq('javascript')
    end
    it 'return javascript comment' do
      expect(FileHelper.get_comment_syntax(@submission_file.filename)).to eq(%w[/* */])
    end
  end

  context 'A .html Submission file' do
    before(:each) do
      @submission_file = SubmissionFile.create(filename: 'filename.html',
                                               path: 'path',
                                               submission_id: 1)
    end
    it 'return html' do
      expect(FileHelper.get_file_type(@submission_file.filename)).to eq('html')
    end
    it 'return html comment' do
      expect(FileHelper.get_comment_syntax(@submission_file.filename)).to eq(%w[<!-- -->])
    end
  end

  context 'A .css Submission file' do
    before(:each) do
      @submission_file = SubmissionFile.create(filename: 'filename.css',
                                               path: 'path',
                                               submission_id: 1)
    end
    it 'return css' do
      expect(FileHelper.get_file_type(@submission_file.filename)).to eq('css')
    end
    it 'return css comment' do
      expect(FileHelper.get_comment_syntax(@submission_file.filename)).to eq(%w[/* */])
    end
  end

  context 'A .c Submission file' do
    before(:each) do
      @submission_file = SubmissionFile.create(filename: 'filename.c',
                                               path: 'path',
                                               submission_id: 1)
    end
    it 'return c' do
      expect(FileHelper.get_file_type(@submission_file.filename)).to eq('c')
    end
    it 'return c comment' do
      expect(FileHelper.get_comment_syntax(@submission_file.filename)).to eq(%w[/* */])
    end
  end

  context 'A .tex Submission file' do
    before(:each) do
      @submission_file = SubmissionFile.create(filename: 'filename.tex',
                                               path: 'path',
                                               submission_id: 1)
    end
    it 'return tex' do
      expect(FileHelper.get_file_type(@submission_file.filename)).to eq('tex')
    end
  end

  context 'A no extension Submission file' do
    before(:each) do
      @submission_file = SubmissionFile.create(filename: 'filename',
                                               path: 'path',
                                               submission_id: 1)
    end
    it 'return a unknown file extension' do
      expect(FileHelper.get_file_type(@submission_file.filename)).to eq('unknown')
    end
    it 'return generic comment' do
      expect(FileHelper.get_comment_syntax(@submission_file.filename)).to eq(%w[## ##])
    end
  end

  context 'An unknown Submission file' do
    before(:each) do
      @submission_file = SubmissionFile.create(filename: 'filename.toto',
                                               path: 'path',
                                               submission_id: 1)
    end
    it 'return a unknown file extension' do
      expect(FileHelper.get_file_type(@submission_file.filename)).to eq('unknown')
    end
    it 'return generic comment' do
      expect(FileHelper.get_comment_syntax(@submission_file.filename)).to eq(%w[## ##])
    end
  end

  context 'A supported image' do
    before(:each) do
      # currently supported formats: ['.jpeg', '.jpg', '.gif', '.png']
      @jpeg_file = SubmissionFile.create(filename: 'filename.jpeg',
                                         path: 'path',
                                         submission_id: 1)
      @jpg_file = SubmissionFile.create(filename: 'filename.jpg',
                                        path: 'path',
                                        submission_id: 2)
      @gif_file = SubmissionFile.create(filename: 'filename.gif',
                                        path: 'path',
                                        submission_id: 3)
      @png_file = SubmissionFile.create(filename: 'filename.png',
                                        path: 'path',
                                        submission_id: 4)
      @heic_file = SubmissionFile.create(filename: 'filename.heic',
                                         path: 'path',
                                         submission_id: 5)
      @heif_file = SubmissionFile.create(filename: 'filename.heif',
                                         path: 'path',
                                         submission_id: 6)
      @unsupported_file = SubmissionFile.create(filename: 'filename.bmp',
                                                path: 'path',
                                                submission_id: 7)
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
    it 'returns \'image\' when checking file type' do
      expect(FileHelper.get_file_type(@jpeg_file.filename)).to eq 'image'
      expect(FileHelper.get_file_type(@jpg_file.filename)).to eq 'image'
      expect(FileHelper.get_file_type(@gif_file.filename)).to eq 'image'
      expect(FileHelper.get_file_type(@png_file.filename)).to eq 'image'
      expect(FileHelper.get_file_type(@heic_file.filename)).to eq 'image'
      expect(FileHelper.get_file_type(@heif_file.filename)).to eq 'image'
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
          @ta = Ta.new(user_attributes: { user_name: 'exist_user',
                                          first_name: 'Nelle',
                                          last_name: 'Varoquaux',
                                          type: 'EndUser' })
          @annot1 = ImageAnnotation.new({ submission_file: @submission_file,
                                          x1: 0, x2: 10, y1: 0, y2: 10, id: 3,
                                          annotation_text: AnnotationText.new({ id: 1 }),
                                          creator: @ta })
          @annot2 = ImageAnnotation.new({ submission_file: @submission_file,
                                          x1: 57, x2: 73, y1: 2, y2: 100, id: 4,
                                          annotation_text: AnnotationText.new({ id: 2 }),
                                          creator: @ta })
        end
        it 'return a corresponding array' do
          @submission_file.annotations.push(@annot1)
          @submission_file.annotations.push(@annot2)
          expect(@submission_file.get_annotation_grid.sort_by { |x| x[:id] })
            .to eq([{ id: 1, annot_id: 3, x_range: { start: 0, end: 10 },
                      y_range: { start: 0, end: 10 } },
                    { id: 2, annot_id: 4, x_range: { start: 57, end: 73 },
                      y_range: { start: 2, end: 100 } }])
        end
      end
    end

    context 'from a pdf file' do
      before(:each) do
        @submission_file = SubmissionFile.create(filename: 'filename.pdf',
                                                 path: 'path')
      end
      context 'with no annotations' do
        it 'return []' do
          expect(@submission_file.get_annotation_grid).to eq([])
        end
      end
      context 'with valid annotations' do
        before(:each) do
          @ta = Ta.new(user_attributes: { user_name: 'exist_user',
                                          first_name: 'Nelle',
                                          last_name: 'Varoquaux',
                                          type: 'EndUser' })
          @annot1 = ImageAnnotation.new({ submission_file: @submission_file,
                                          x1: 0, x2: 10, y1: 0, y2: 10, id: 3,
                                          annotation_text: AnnotationText.new({ id: 1 }),
                                          creator: @ta })
          @annot2 = ImageAnnotation.new({ submission_file: @submission_file,
                                          x1: 57, x2: 73, y1: 2, y2: 100, id: 4,
                                          annotation_text: AnnotationText.new({ id: 2 }),
                                          creator: @ta })
        end
        it 'return a corresponding array' do
          @submission_file.annotations.push(@annot1)
          @submission_file.annotations.push(@annot2)
          expect(@submission_file.get_annotation_grid.sort_by { |x| x[:id] })
            .to eq([{ id: 1, annot_id: 3, x_range: { start: 0, end: 10 },
                      y_range: { start: 0, end: 10 } },
                    { id: 2, annot_id: 4, x_range: { start: 57, end: 73 },
                      y_range: { start: 2, end: 100 } }])
        end
      end
      context 'when checking the file type' do
        it 'returns \'pdf\'' do
          expect(FileHelper.get_file_type(@submission_file.filename)).to eq 'pdf'
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

  context '#add_annotations' do
    it 'includes deductive information when deductive annotations applied' do
      pending('retrieve_file() not yet usable in testing, and add_annotations is private.')
      assignment = create(:assignment_with_deductive_annotations)
      file = create(:submission_file, submission: assignment.groupings.first.current_result.submission)
      category = assignment.annotation_categories.where.not(flexible_criterion_id: nil).first
      text = category.annotation_texts.first
      create(:text_annotation,
             annotation_text: text,
             submission_file: file,
             result: assignment.groupings.first.current_result)
      deductive_info = " [#{category.flexible_criterion.name}: -#{text.deduction}]"
      expect(file.retrieve_file.include?(deductive_info)).to be true
    end
  end
end
