describe FileHelper do
  # Replace unwanted and unconventional characters in a filename to make filename format's consistent
  context 'A new file when submitted' do
    context "containing characters outside what's allowed in a filename" do
      before do
        @filenames_to_be_sanitized = [{ expected: 'llll_', orig: 'llllé' },
                                      { expected: '________', orig: 'öä*?`ßÜÄ' },
                                      { expected: '', orig: nil },
                                      { expected: 'garbage-__.txt', orig: 'garbage-éæ.txt' },
                                      { expected: 'space space.txt', orig: 'space space.txt' },
                                      { expected: '      .txt', orig: '      .txt' },
                                      { expected: 'garbage-__.txt', orig: 'garbage-éæ.txt' }]
      end

      it 'have sanitized them properly' do
        @filenames_to_be_sanitized.each do |item|
          expect(FileHelper.sanitize_file_name(item[:orig])).to eq item[:expected]
        end
      end
    end

    context 'containing only valid characters in a filename' do
      before do
        @filenames_not_to_be_sanitized = %w[valid_file.sh
                                            valid_001.file.ext
                                            valid-master.png
                                            some__file___.org-png
                                            001.txt]
      end

      it 'NOT have sanitized away any of their characters' do
        @filenames_not_to_be_sanitized.each do |orig|
          expect(FileHelper.sanitize_file_name(orig)).to eq orig
        end
      end
    end
  end

  context 'A .java Submission file' do
    it 'return java' do
      expect(FileHelper.get_file_type('filename.java')).to eq('java')
    end

    it 'return java comment' do
      expect(FileHelper.get_comment_syntax('filename.java')).to eq(%w[/* */])
    end
  end

  context 'A .rb Submission file' do
    it 'return ruby' do
      expect(FileHelper.get_file_type('filename.rb')).to eq('ruby')
    end

    it 'return ruby comment' do
      expect(FileHelper.get_comment_syntax('filename.rb')).to eq(%W[=begin\n \n=end])
    end
  end

  context 'A .py Submission file' do
    it 'return python' do
      expect(FileHelper.get_file_type('filename.py')).to eq('python')
    end

    it 'return python comment' do
      expect(FileHelper.get_comment_syntax('filename.py')).to eq(%w[""" """])
    end
  end

  context 'A .js Submission file' do
    it 'return javascript' do
      expect(FileHelper.get_file_type('filename.js')).to eq('javascript')
    end

    it 'return javascript comment' do
      expect(FileHelper.get_comment_syntax('filename.js')).to eq(%w[/* */])
    end
  end

  context 'A .html Submission file' do
    it 'return html' do
      expect(FileHelper.get_file_type('filename.html')).to eq('html')
    end

    it 'return html comment' do
      expect(FileHelper.get_comment_syntax('filename.html')).to eq(%w[<!-- -->])
    end
  end

  context 'A .css Submission file' do
    it 'return css' do
      expect(FileHelper.get_file_type('filename.css')).to eq('css')
    end

    it 'return css comment' do
      expect(FileHelper.get_comment_syntax('filename.css')).to eq(%w[/* */])
    end
  end

  context 'A .c Submission file' do
    it 'return c' do
      expect(FileHelper.get_file_type('filename.c')).to eq('c')
    end

    it 'return c comment' do
      expect(FileHelper.get_comment_syntax('filename.c')).to eq(%w[/* */])
    end
  end

  context 'A .tex Submission file' do
    it 'return tex' do
      expect(FileHelper.get_file_type('filename.tex')).to eq('tex')
    end

    it 'return a tex comment' do
      expect(FileHelper.get_comment_syntax('filename.tex')).to eq(%w[## ##])
    end
  end

  context 'A .zip Submission file' do
    it 'return binary' do
      expect(FileHelper.get_file_type('filename.zip')).to eq('binary')
    end

    it 'return a binary comment' do
      expect(FileHelper.get_comment_syntax('filename.zip')).to eq(%w[## ##])
    end
  end

  context 'A no extension Submission file' do
    it 'return a unknown file extension' do
      expect(FileHelper.get_file_type('filename')).to eq('unknown')
    end

    it 'return generic comment' do
      expect(FileHelper.get_comment_syntax('filename')).to eq(%w[## ##])
    end
  end

  context 'A supported image' do
    before do
      # currently supported formats: ['.jpeg', '.jpg', '.gif', '.png']
      @jpeg_file = 'filename.jpeg'
      @jpg_file = 'filename.jpg'
      @gif_file = 'filename.gif'
      @png_file = 'filename.png'
      @heic_file = 'filename.heic'
      @heif_file = 'filename.heif'
      @unsupported_file = 'filename.bmp'
    end

    it 'returns \'image\' when checking file type' do
      expect(FileHelper.get_file_type(@jpeg_file)).to eq 'image'
      expect(FileHelper.get_file_type(@jpg_file)).to eq 'image'
      expect(FileHelper.get_file_type(@gif_file)).to eq 'image'
      expect(FileHelper.get_file_type(@png_file)).to eq 'image'
      expect(FileHelper.get_file_type(@heic_file)).to eq 'image'
      expect(FileHelper.get_file_type(@heif_file)).to eq 'image'
    end
  end
end
