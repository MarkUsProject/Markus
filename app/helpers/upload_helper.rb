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

  # Unzip the file at +zip_file_path+ and return a list of all directory paths in the zipped file as well as a list of
  # UploadedFile objects that contain the data from all files in the zipped file.
  def unzip_uploaded_file(zip_file_path)
    unzipped_files = []
    unzipped_dirs = []
    Zip::File.open(zip_file_path) do |zipfile|
      zipfile.each do |zf|
        unzipped_dirs << zf.name if zf.directory?
        if zf.file?
          mime = Rack::Mime.mime_type(File.extname(zf.name))
          tempfile = Tempfile.new.binmode
          tempfile.write(zf.get_input_stream.read)
          tempfile.rewind
          unzipped_files << ActionDispatch::Http::UploadedFile.new(filename: zf.name, tempfile: tempfile, type: mime)
        end
      end
    end
    [unzipped_dirs, unzipped_files]
  end
end
