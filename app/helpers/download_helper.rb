# Helpers for handling downloading data files for various models.
module DownloadHelper
  # Wrapper around +send_file+ which forces the +disposition+ optional argument to
  # 'attachment' since this method  should only be used to download files.
  def send_file_download(path, options = {})
    send_file path, **options, type: Rack::Mime.mime_type(File.extname(path)), disposition: 'attachment'
  end

  # Wrapper around +send_data+ which forces the +disposition+ optional argument to
  # 'attachment' since this method  should only be used to download the data as a file.
  def send_data_download(data, options = {})
    options = { **options, type: Rack::Mime.mime_type(File.extname(options[:filename])) } if options.key?(:filename)
    send_data data, **options, disposition: 'attachment'
  end
end
