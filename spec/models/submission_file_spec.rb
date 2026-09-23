describe SubmissionFile do
  # Ensure that the the following relationship exists
  it { is_expected.to belong_to(:submission) }
  it { is_expected.to have_many(:annotations) }
  it { is_expected.to validate_presence_of :filename }
  it { is_expected.to validate_presence_of :path }
  it { is_expected.to have_one(:course) }

  context 'A .java Submission file' do
    before do
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
    before do
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
    before do
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
    before do
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
    before do
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
    before do
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
    before do
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
    before do
      @submission_file = SubmissionFile.create(filename: 'filename.tex',
                                               path: 'path',
                                               submission_id: 1)
    end

    it 'return tex' do
      expect(FileHelper.get_file_type(@submission_file.filename)).to eq('tex')
    end
  end

  context 'A no extension Submission file' do
    before do
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
    before do
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
    before do
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
      before do
        @submission_file = SubmissionFile.create(filename: 'filename',
                                                 path: 'path')
      end

      it 'return nil' do
        expect(@submission_file.get_annotation_grid).to be_nil
      end
    end

    context 'from an image file' do
      before do
        @submission_file = SubmissionFile.create(filename: 'filename.jpeg',
                                                 path: 'path')
      end

      context 'with no annotations' do
        it 'return []' do
          expect(@submission_file.get_annotation_grid).to eq([])
        end
      end

      context 'with valid annotations' do
        before do
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
      before do
        @submission_file = SubmissionFile.create(filename: 'filename.pdf',
                                                 path: 'path')
      end

      context 'with no annotations' do
        it 'return []' do
          expect(@submission_file.get_annotation_grid).to eq([])
        end
      end

      context 'with valid annotations' do
        before do
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

  describe '#add_annotations' do
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

  describe '#annotation_class' do
    it 'returns ImageAnnotation for an image file' do
      expect(build(:image_submission_file).annotation_class).to eq(ImageAnnotation)
    end

    it 'returns PdfAnnotation for a pdf file' do
      expect(build(:pdf_submission_file).annotation_class).to eq(PdfAnnotation)
    end

    it 'returns HtmlAnnotation for a notebook file' do
      expect(build(:notebook_submission_file).annotation_class).to eq(HtmlAnnotation)
    end

    it 'returns TextAnnotation for a plaintext file' do
      expect(build(:submission_file, filename: 'foo.py').annotation_class).to eq(TextAnnotation)
    end

    context 'for an RMarkdown file' do
      let(:rmd_file) { build(:rmd_submission_file) }

      it 'returns HtmlAnnotation when rmd_convert_enabled is true' do
        allow(Rails.application.config).to receive(:rmd_convert_enabled).and_return(true)
        expect(rmd_file.annotation_class).to eq(HtmlAnnotation)
      end

      it 'returns TextAnnotation when rmd_convert_enabled is false' do
        allow(Rails.application.config).to receive(:rmd_convert_enabled).and_return(false)
        expect(rmd_file.annotation_class).to eq(TextAnnotation)
      end
    end
  end

  describe '#retrieve_file' do
    let(:result) { create(:complete_result) }
    let(:file_contents) { "first line\nsecond line\n" }

    before do
      revision = instance_double(Repository::AbstractRevision)
      repo = instance_double(Repository::AbstractRepository)
      allow(revision).to receive(:files_at_path).and_return({ submission_file.filename => :revision_file })
      allow(repo).to receive_messages(get_revision: revision, download_as_string: file_contents)
      allow_any_instance_of(Grouping).to receive(:access_repo).and_yield(repo)
    end

    context 'with a plaintext submission file' do
      let(:submission_file) { create(:submission_file, filename: 'example.py', submission: result.submission) }
      let!(:annotation) do
        create(:text_annotation, result: result, submission_file: submission_file, annotation_number: 1,
                                 line_start: 1, line_end: 1)
      end

      it 'does not modify the file when include_annotations is false' do
        expect(submission_file.retrieve_file).to eq(file_contents)
      end

      it 'surrounds the annotated lines with comments when include_annotations is true' do
        expect(submission_file.retrieve_file(include_annotations: true)).to include(
          "ANNOTATION 1: #{annotation.annotation_text.content}"
        )
      end
    end

    context 'with a PDF submission file' do
      let(:submission_file) { create(:pdf_submission_file, submission: result.submission) }
      let(:file_contents) do
        Prawn::Document.new do |doc|
          doc.text 'page 1'
          doc.start_new_page
          doc.text 'page 2'
        end.render
      end

      # The annotations of the PDF page at the given (one-based) index, as PDF dictionaries.
      def page_annotations(contents, page_index)
        annots = CombinePDF.parse(contents).pages[page_index - 1][:Annots] || []
        annots.map { |annot| annot[:referenced_object] || annot }
      end

      # Parse a sticky note's :M entry, which is a PDF date string (e.g. "D:20260923134500-04'00'").
      def note_updated_at(annot)
        DateTime.strptime(annot[:M].delete("'"), 'D:%Y%m%d%H%M%S%z').to_time
      end

      def annotation_contents(annot)
        annot[:Contents].dup.force_encoding(Encoding::UTF_16BE).encode(Encoding::UTF_8).delete_prefix("\uFEFF")
      end

      context 'when the file has no annotations' do
        it 'returns the file unchanged' do
          expect(submission_file.retrieve_file(include_annotations: true)).to eq(file_contents)
        end
      end

      context 'when the file has annotations' do
        let!(:annotation) do
          create(:pdf_annotation, result: result, submission_file: submission_file, annotation_number: 3,
                                  page: 2, x1: 10_000, y1: 20_000, x2: 30_000, y2: 40_000)
        end

        it 'does not modify the file when include_annotations is false' do
          expect(submission_file.retrieve_file).to eq(file_contents)
        end

        it 'adds a sticky note to the page the annotation is on' do
          contents = submission_file.retrieve_file(include_annotations: true)
          expect(page_annotations(contents, 1)).to be_empty
          expect(page_annotations(contents, 2).pluck(:Subtype)).to eq([:Text])
        end

        it 'includes the annotation number and text in the sticky note' do
          contents = submission_file.retrieve_file(include_annotations: true)
          expect(annotation_contents(page_annotations(contents, 2).first))
            .to eq("(#3) #{annotation.annotation_text.content}")
        end

        it 'records when the annotation was last updated' do
          annotation.update!(updated_at: 2.days.ago)
          annotation.annotation_text.update!(updated_at: 3.days.ago)
          contents = submission_file.retrieve_file(include_annotations: true)
          expect(note_updated_at(page_annotations(contents, 2).first)).to be_within(1).of(annotation.updated_at)
        end

        it 'records the annotation text timestamp when the text was edited more recently' do
          annotation.update!(updated_at: 3.days.ago)
          annotation.annotation_text.update!(updated_at: 2.days.ago)
          contents = submission_file.retrieve_file(include_annotations: true)
          expect(note_updated_at(page_annotations(contents, 2).first))
            .to be_within(1).of(annotation.annotation_text.updated_at)
        end

        it 'places the sticky note at the annotation location' do
          contents = submission_file.retrieve_file(include_annotations: true)
          left, bottom, right, top = page_annotations(contents, 2).first[:Rect].map(&:to_f)
          # The note is a 20pt square centred on the annotation's top left corner, which is
          # 10% across and 20% down a 612x792 page (measured from its top left corner).
          expect((left + right) / 2).to be_within(0.01).of(0.1 * 612)
          expect((bottom + top) / 2).to be_within(0.01).of(792 - (0.2 * 792))
          expect(right - left).to be_within(0.01).of(20)
          expect(top - bottom).to be_within(0.01).of(20)
        end

        it 'leaves the pages of the file intact' do
          expect(CombinePDF.parse(submission_file.retrieve_file(include_annotations: true)).pages.size)
            .to eq(CombinePDF.parse(file_contents).pages.size)
        end
      end
    end
  end
end
