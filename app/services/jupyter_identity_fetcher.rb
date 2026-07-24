# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

class JupyterIdentityFetcher
  class IdentityError < StandardError; end

  def initialize(origin:, base_url:, token:)
    @origin = normalize_origin(origin)
    @base_url = normalize_base_url(base_url)
    @token = token.to_s
  end

  def username
    # Local development fallback only.
    # This allows standalone JupyterLab testing where there is no JupyterHub identity endpoint.
    if Rails.env.development? && Settings.jupyter_server.dev_username.present?
      Rails.logger.info(
        "[JupyterIdentityFetcher] Using development username #{Settings.jupyter_server.dev_username}"
      )
      return Settings.jupyter_server.dev_username
    end

    validate!

    uri = hub_user_uri

    Rails.logger.info("[JupyterIdentityFetcher] Fetching identity from #{uri}")

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
      raise IdentityError,
            "JupyterHub identity lookup returned HTTP #{response.code}: #{response.body}"
    end

    model = JSON.parse(response.body)
    name = model['name'] || model['username']

    if name.blank?
      raise IdentityError,
            'JupyterHub identity response did not include a username.'
    end

    name
  rescue JSON::ParserError => e
    raise IdentityError,
          "JupyterHub identity response was not valid JSON: #{e.message}"
  rescue Errno::ECONNREFUSED, SocketError, Net::OpenTimeout, Net::ReadTimeout => e
    raise IdentityError,
          "Could not connect to JupyterHub identity endpoint: #{e.message}"
  end

  private

  def validate!
    raise IdentityError, 'Missing Jupyter token.' if @token.blank?
  end

  def hub_user_uri
    URI.parse("#{@origin}/hub/api/user")
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
