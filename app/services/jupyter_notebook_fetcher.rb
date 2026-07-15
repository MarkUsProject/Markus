# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

class JupyterNotebookFetcher
  class FetchError < StandardError; end

  def initialize(origin:, base_url:, token:, notebook_path:)
    @origin = normalize_origin(origin)
    @base_url = normalize_base_url(base_url)
    @token = token
    @notebook_path = notebook_path
  end

  def fetch
    uri = contents_uri

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
      raise FetchError, "Jupyter returned HTTP #{response.code} for #{uri}: #{response.body}"
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
    raise FetchError, "Jupyter returned invalid JSON: #{e.message}"
  rescue Errno::ECONNREFUSED, SocketError, Net::OpenTimeout, Net::ReadTimeout => e
    raise FetchError, "Could not connect to Jupyter: #{e.message}"
  end

  private

  def contents_uri
    encoded_path = @notebook_path
                   .split('/')
                   .reject(&:blank?)
                   .map { |part| URI.encode_www_form_component(part) }
                   .join('/')

    uri = URI.join( "#{@origin}#{@base_url}", "api/contents/#{encoded_path}" )
    uri.query = URI.encode_www_form(content: '1')
    uri
  end
end
