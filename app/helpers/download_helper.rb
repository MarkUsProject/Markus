# Helpers for handling downloading data files for various models.
module DownloadHelper
  MIME_TYPE_CONVERSION = { 'application/javascript': 'text/plain',
                           'text/javascript': 'text/plain' }.stringify_keys.freeze

  # Wrapper around +send_file+ which converts the +type+ optional argument according
  # to the +MIME_TYPE_CONVERSION+ hash.
  # This also forces the +disposition+ optional argument to 'attachment' since this method
  # should only be used to download files.
  # For example, it will make sure a file with a .js extension will be downloaded as
  # plain text which avoids a ActionController::InvalidCrossOriginRequest, which is raised
  # whenever +send_file+ is asked to download a javascript file.
  def send_file_download(path, options = {})
    send_file path, **options, type: get_converted_mime_type(path), disposition: 'attachment'
  end

  # Wrapper around +send_data+ which converts the +type+ optional argument according
  # to the +MIME_TYPE_CONVERSION+ hash.
  # This also forces the +disposition+ optional argument to 'attachment' since this method
  # should only be used to download the data as a file.
  # For example, it will make sure a file with a .js extension will be downloaded as
  # plain text which avoids a ActionController::InvalidCrossOriginRequest, which is raised
  # whenever +send_file+ is asked to download a javascript file.
  def send_data_download(data, options = {})
    options = { **options, type: get_converted_mime_type(options[:filename]) } if options.key?(:filename)
    send_data data, **options, disposition: 'attachment'
  end

  private

  def get_converted_mime_type(filepath)
    current_mime_type = Rack::Mime.mime_type(File.extname(filepath))
    MIME_TYPE_CONVERSION.fetch(current_mime_type) { current_mime_type }
  end
end
