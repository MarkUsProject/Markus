#!/usr/bin/ruby
# The intention of this Ryby script is to provide
# MarkUs users with a tool which is able to generate HTTP's
# GET, PUT, DELETE and POST requests. This may be handy for
# users planning to use MarkUs' Web API.
#
#  DISCLAIMER
# This script is made available under the OSI-approved
# MIT license. See http://www.markusproject.org/#license for
# more information. WARNING: This script is still considered
# experimental.
#
# (c) by the authors, 2008 - 2010.
#

begin
  # in order to parse console arguments
  require 'getoptlong'
  # in order to parse url
  require 'uri'
  # in order to perform http requests
  require 'net/http'
rescue LoadError => e
  $stderr.puts("Required library not found: '#{e.message}'.")
  exit(1)
end

OPTS = GetoptLong.new(
      [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
      [ '--request-type', '-r', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--binary', '-b', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--api-key-file', '-k', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--url', '-u', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--test-file', '-t', GetoptLong::OPTIONAL_ARGUMENT ],
      [ '--verbose', '-v', GetoptLong::NO_ARGUMENT ]
    )

# In case people don't know what they're doing...
def usage
  usage = "#{$0} -r HTTP_R -k KEY -u URL [options] [param=value param=value ...]"
  usage += "\n\n\tTry: #{$0} -h for more information."
  return usage
end

def help
  message = "MarkUs utility script to generate GET, PUT, POST,"
  message += "DELETE HTTP requests. It automatically crafts and sends HTTP requests"
  message += "to the specified MarkUs API URL."

  message += "\n\n== Usage ==\n"
  message += "  -b, --binary       \t  Path to binary file. This works only for PUT and POST.\n"
  message += "  -h, --help         \t  Print this help message .\n"
  message += "  -k, --api-key-file \t  File containing your API key for MarkUs. Required.\n"
  message += "  -r, --request-type \t  The HTTP request type to generate. One of {PUT,GET,POST,DELETE}. Required.\n"
  message += "  -u, --url          \t  The url of the resource to send the HTTP request to. Required.\n"
  message += "  -v, --verbose      \t  Print response body in addition to the HTTP status code and reason.\n"
  message += "  -t, --test-file    \t  File containing your test result for MarkUs. Will be ignored if file_content='...' is provided.\n"

  return message
end

def load_params()
  # By default, non verbose output
  params = {:verbose => false}

  OPTS.each do |opt, arg|
    case opt
      when '--help'
        $stdout.puts usage()
        $stdout.puts help()
        exit(0)
      when '--api-key-file'
        params[:api_key_file] = arg
      when '--request-type'
        params[:request_type] = arg.upcase
      when '--url'
        params[:url] = arg.downcase
      when '--test-file'
        params[:test_file] = arg
      when '--verbose'
        params[:verbose] = true
      when '--binary'
        params[:binary] = true
        $stdout.puts "The binary option is not enabled"
      end
  end
  return params
end

def check_params(params)
  # Make sure args list may be valid
  # We need at least this
  if params.length < 3
    $stderr.puts usage()
    #We return a error status
    exit(1)
  end

  # Make sure HTTP request type is provided
  if !params.has_key?( :request_type)
    $stderr.puts usage()
    exit(1)
  end

   # Make sure API key is provided
  if !params.has_key?( :api_key_file )
    $stderr.puts usage()
    exit(1)
  end

  # Make sure an URL to post to is provided
  if !params.has_key?( :url)
    $stderr.puts usage()
    exit(1)
  end

  # Make sure we one of the supported request types
  if !(["POST", "GET", "PUT", "DELETE"].include?(params[:request_type]))
    $stderr.puts("Bad request type. Only GET, PUT, POST, DELETE are supported.")
    exit(1)
  end

  # Binary file option only makes sense for PUT/POST
  if params[:binary] == true and !(["POST", "PUT"].include?(params[:request_type]))
     $stderr.puts("Binary file option only allowed for PUT and POST")
     exit(1)
  end

  # Sanity check URL (must be http/https)
  uri = URI.parse(params[:url])
  if !(["http", "https"].include?(uri.scheme))
    $stderr.puts("Only http and https URLs are supported.")
    exit(1)
  end

  return uri
end

def submit_request(params, uri, param_data)
  # Construct desired HTTP request, including proper auth header.
  ##Pre: check_arguments has been run, i.e. we have a proper set of
  #         arguments.
  ##Post: Request crafted and submitted. Response status printed to stdout.

  # Read API key from file
  if File.readable?(params[:api_key_file].strip)
    api_key_file = File.new(params[:api_key_file].strip, "r")
    key = api_key_file.read.strip
    api_key_file.close
  else
    $stderr.puts("#{params[:api_key_file].strip}: File not readable or does not exist!")
    exit(1)
  end
  # Construct auth header string
  auth_header = "MarkUsAuth #{key}"

  # Prepare header parameter for connection. MarkUs auth header, plus
  # need 'application/x-www-form-urlencoded' header for parameters to go through
  headers = Hash.new
  headers['Authorization'] = auth_header
  headers['Content-type'] = "application/x-www-form-urlencoded"

  http = Net::HTTP.new(uri.host, uri.port)

  # Enable SSL if uri.scheme indicates so
  if (uri.scheme == "https")
    begin
      # in order to perform https requests
      require 'net/https'
    rescue LoadError => e
      $stderr.puts("Required library not found: '#{e.message}'.")
      exit(1)
    end
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  response = http.send_request(params[:request_type], uri.request_uri, param_data, headers)
  if params[:verbose]
    puts "#{response.body}\n#{response.code} #{response.message}"
  else
    puts "#{response.code} #{response.message}"
  end

 end

def parse_parameters(params)
  param_array = []
  # Read File Content argument from a file
  if params.has_key?( :test_file )
    if File.readable?(params[:test_file].strip)
      test_file = File.new(params[:test_file].strip, "r")
      content = test_file.read.strip
      test_file.close
      param_array.push("file_content=" + URI.escape(content))
    else
      $stderr.puts("#{params[:test_file].strip}: File not readable or does not exist!")
      exit(1)
    end
  end
  # Parses parameters passed in as arguments and returns them as Rest compliant String
  ARGV.each do |argv|
    a = argv.split('=', 2)
    a.map { |item| URI.escape(item) } # uri escape items in array
    param_array.push(a.join('='))
  end

  return param_array.join('&')
end

if __FILE__ == $0

  # We are loading parameters from command line
  params = load_params()
  # We check all parameters and return the uri
  uri = check_params(params)
  # Parse parameters (param=...)
  param_data = parse_parameters(params)

  begin
    # We submit the request to MarkUs API
    submit_request(params, uri, param_data)
  rescue URI::InvalidURIError => e
    $stderr.puts "Invalid URL. Error was #{e.message}"
    exit(1)
  rescue Errno::ECONNREFUSED => e
    $stderr.puts "#{uri.to_s} #{e.message}"
    exit(1)
  end

end
