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
end
