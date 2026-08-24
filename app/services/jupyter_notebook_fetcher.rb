# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

class JupyterNotebookFetcher
  class FetchError < StandardError; end

  def initialize(origin:, base_url:, token:, notebook_path:)
    @origin = normalize_origin(origin)
    @base_url = normalize_base_url(base_url)
    @token = token.to_s
    @notebook_path = notebook_path.to_s
  end

  def fetch
    validate!

    uri = contents_uri

    Rails.logger.info(
      "[JupyterNotebookFetcher] Fetching notebook from #{uri}"
    )

    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/json'
    request['Authorization'] = "token #{@token}"

    response = Net::HTTP.start(
      uri.hostname,
      uri.port,
      use_ssl: uri.scheme == 'https',
      open_timeout: 10,
      read_timeout: 30
    ) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise FetchError,
            "Jupyter returned HTTP #{response.code} for #{uri}: #{response.body}"
    end

    model = JSON.parse(response.body)

    {
      name: model['name'],
      path: model['path'],
      type: model['type'],
      format: model['format'],
      mimetype: model['mimetype'],
      writable: model['writable'],
      content: model['content']
    }
  rescue JSON::ParserError => e
    raise FetchError,
          "Jupyter returned invalid JSON: #{e.message}"
  rescue URI::InvalidURIError => e
    raise FetchError,
          "Invalid Jupyter URL: #{e.message}"
  rescue Errno::ECONNREFUSED,
         SocketError,
         Net::OpenTimeout,
         Net::ReadTimeout => e
    raise FetchError,
          "Could not connect to Jupyter: #{e.message}"
  end

  private

  def validate!
    raise FetchError, 'Missing Jupyter token.' if @token.blank?

    if @notebook_path.blank?
      raise FetchError, 'Missing notebook path.'
    end

    if @origin.blank?
      raise FetchError, 'Missing Jupyter origin.'
    end
  end

  def contents_uri
    encoded_path = @notebook_path
                   .split('/')
                   .reject(&:blank?)
                   .map { |part| URI.encode_www_form_component(part) }
                   .join('/')

    uri = URI.join(
      "#{@origin}#{@base_url}",
      "api/contents/#{encoded_path}"
    )

    uri.query = URI.encode_www_form(content: '1')
    uri
  end

  def normalize_origin(origin)
    configured_origin = Settings.jupyter_server.api_origin.presence
    value = configured_origin || origin.to_s

    value.strip.sub(%r{/*\z}, '')
  end

  def normalize_base_url(base_url)
    value = base_url.to_s.strip

    return '/' if value.blank?

    if value.start_with?('http://', 'https://')
      parsed = URI.parse(value)
      value = parsed.path.presence || '/'
    end

    value = "/#{value}" unless value.start_with?('/')
    value = "#{value}/" unless value.end_with?('/')

    value
  rescue URI::InvalidURIError
    '/'
  end
end
