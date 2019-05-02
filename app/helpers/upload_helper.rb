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
        contents: YAML.safe_load(upload_file.utf8_encode(encoding), [Date, Time])
      }
    else
      raise StandardError, I18n.t('upload_errors.malformed_csv')
    end
  end
end
