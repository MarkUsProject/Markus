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
        contents: parse_yaml_content(upload_file.read.encode(Encoding::UTF_8, encoding))
      }
    else
      raise StandardError, I18n.t('upload_errors.malformed_csv')
    end
  end

  # Unzip the file at +zip_file_path+ and yield the name of each directory and an
  # UploadedFile object for each file.
  def upload_files_helper(new_folders, new_files, unzip: false, &block)
    new_folders.each(&block)
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

  # Parse the +yaml_string+ and return the data as a hash.
  def parse_yaml_content(yaml_string)
    YAML.safe_load(yaml_string,
                   permitted_classes: [
                     Date, Time, Symbol, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone,
                     ActiveSupport::Duration, ActiveSupport::HashWithIndifferentAccess
                   ],
                   aliases: true)
  end
end
