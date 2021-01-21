# Helpers for handling uploading data files for various models.
module UploadHelper
  def process_file_upload
    encoding = params[:encoding] || 'UTF-8'
    upload_file = params.require(:upload_file)

    if upload_file.size == 0
      raise StandardError, I18n.t('upload_errors.blank')
    end

    filetype = File.extname(upload_file.original_filename)
    if filetype == '.csv'
      {
        type: '.csv',
        file: upload_file,
        encoding: encoding
      }
    elsif %w[.yml .yaml].include? filetype
      {
        type: '.yml',
        contents: YAML.safe_load(
          upload_file.read.encode(Encoding::UTF_8, encoding),
          [Date, Time, Symbol, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone],
          [],
          true # Allow aliases in YML file
        )
      }
    else
      raise StandardError, I18n.t('upload_errors.malformed_csv')
    end
  end

  # Unzip the file at +zip_file_path+ and yield the name of each directory and an
  # UploadedFile object for each file.
  def upload_files_helper(new_folders, new_files, unzip: false)
    new_folders.each do |f|
      yield f
    end
    new_files.each do |f|
      if unzip && File.extname(f.path).casecmp?('.zip')
        Zip::File.open(f.path) do |zipfile|
          zipfile.each do |zf|
            yield zf.name if zf.directory?
            if zf.file?
              mime = Rack::Mime.mime_type(File.extname(zf.name))
              tempfile = Tempfile.new.binmode
              tempfile.write(zf.get_input_stream.read)
              tempfile.rewind
              yield ActionDispatch::Http::UploadedFile.new(filename: zf.name, tempfile: tempfile, type: mime)
            end
          end
        end
      else
        yield f
      end
    end
  end
end
