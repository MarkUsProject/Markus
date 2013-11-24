# Get's the login-form and parses the authenticity token
# Uses the authenticity token to construct post-requests for
#     - login
#     - submissions

if __FILE__ == $0
  require 'net/http' # need net/http for constructing requests
  require 'uri'      # URI parsing lib
  require 'fileutils'
  require 'digest/md5' # required for boundary MD5 hashing

  def get_file_header(file_name, boundary)
    head = "--#{boundary}" + CRLF
    head += "Content-Disposition: form-data; name=\"new_files[]\"; filename=\"#{file_name}\"" + CRLF
    head += "Content-Type: application/x-ruby" + CRLF + CRLF
    return head
  end

  if ARGV[0].nil?
    puts "usage: construct_requests.rb APP_URI [students_logins_file]"
    exit 1
  end

  # Constants:
  # - URI's to post to
  # - File paths, etc
  APP_URI = ARGV[0]
  LOGIN_URI = APP_URI + "/"
  SUBMISSION_URI = APP_URI + "/main/submissions/file_manager/1"
  HOME_REQUESTS = "requests"
  POST_DIR = "posts"
  LOGIN_DIR = "logins"
  SUBMISSION_DIR = "submissions"
  BOUNDARY_DIR = "boundaries"
  COOKIES_DIR = "cookies"
  STUDENTS_LIST_FILE = ARGV[1] || "student_logins.txt"
  SUBMISSION_RES_DIR = File.join(File.dirname(__FILE__), "submission_files")
  CRLF = "\r\n" # convenience constant
  WITH_AUTH_TOKEN = false

  # cleanup from previous runs
  if File.exist?(HOME_REQUESTS)
    FileUtils.rm_r(HOME_REQUESTS)
  end

  # creat directory structure
  FileUtils.mkdir_p(File.join(HOME_REQUESTS, POST_DIR, LOGIN_DIR))
  FileUtils.mkdir_p(File.join(HOME_REQUESTS, POST_DIR, SUBMISSION_DIR))
  FileUtils.mkdir_p(File.join(HOME_REQUESTS, COOKIES_DIR))
  FileUtils.mkdir_p(File.join(HOME_REQUESTS, BOUNDARY_DIR))

  students = File.new(File.join(File.dirname(__FILE__), STUDENTS_LIST_FILE)).readlines
  students.each do |login|
    # construct some login requests
    login = login.strip
    login_url = URI.parse(LOGIN_URI)
    req = Net::HTTP::Get.new(login_url.path)
    res = Net::HTTP.start(login_url.host, login_url.port) {|http|
      http.request(req)
    }
    if !res.instance_of?(Net::HTTPOK)
      raise "Unable to get login page!"
    end
    #require "debug"
    # get auth token
    if WITH_AUTH_TOKEN
      auth_token = ""
      if /<input([^>]+name="authenticity_token"[^>]+)\/>/.match(res.body)
        input = $1
        if /value="([^"]+)"/.match(input)
          auth_token = $1
        end
      end
      if auth_token == ""
        raise "Bad auth_token"
      end
    end
    # get cookie
    cookie = res.response['set-cookie']
    cookie = cookie[0..(cookie.index(";")-1)]

    post_request = "user_login=#{login}&user_password=somepassword"
    if WITH_AUTH_TOKEN
      post_request += "&authenticity_token=#{auth_token}"
    end
    post_request += "&commit=Log+in" + CRLF

    # submissions post requests
    # need to login first to get the form
    #sleep 1
    post_req = Net::HTTP::Post.new(login_url.path)
    post_req.add_field('Cookie', cookie)
    post_req.add_field('Content-Length', post_request.length)
    post_req.body = post_request
    res = Net::HTTP.start(login_url.host, login_url.port) {|http|
      http.request(post_req)
    }
    fail_count = 0
    if res.instance_of?(Net::HTTPClientError)
      fail_count +=1
      next
    end

    # construct post-body-file for login
    File.open(File.join(HOME_REQUESTS, POST_DIR, LOGIN_DIR, login), "w") { |file|
      file.write(post_request)
    }
    # write cookie file for login
    File.open(File.join(HOME_REQUESTS, COOKIES_DIR, login), "w") { |file|
      file.write(cookie + "\n")
    }

    #require "debug"
    req = Net::HTTP::Get.new(login_url.path)
    req.add_field('Cookie', cookie)
    res2 = Net::HTTP.start(login_url.host, login_url.port) {|http|
      http.request(req)
    }
    #require "debug"
    assignment_url = URI.parse("http://b2270-02.red.sandbox/markus/app1/main/assignments/student_interface/1")
    get_req = Net::HTTP::Get.new(assignment_url.path)
    get_req.add_field('Cookie', cookie)
    res3 = Net::HTTP.start(assignment_url.host, assignment_url.port) {|http|
      http.request(get_req)
    }
    #require "debug"
    submission_url = URI.parse(SUBMISSION_URI)
    get_req = Net::HTTP::Get.new(submission_url.path)
    get_req.add_field('Cookie', cookie)
    get_req.add_field('Referer', "http://b2270-02.red.sandbox/markus/app1/main/assignments/student_interface/1")
    res4 = Net::HTTP.start(submission_url.host, submission_url.port) {|http|
      http.request(get_req)
    }
    #require 'debug' # debugging
    # get auth token
    if WITH_AUTH_TOKEN
      auth_token = ""
      if /<input([^>]+name="authenticity_token"[^>]+)\/>/.match(res4.body)
        input = $1
        if /value="([^"]+)"/.match(input)
          auth_token = $1
        end
      end
      if auth_token == ""
        raise "Bad auth_token"
      end
    end
    #require 'debug' # debugging

    boundary = Digest::MD5.hexdigest(Time.now.to_f.to_s)
    boundary = "---------------------------" + boundary
    #boundary = Time.now.to_f.to_s.gsub(/\./, "")

    if WITH_AUTH_TOKEN
      submission_post_request_body =  "--#{boundary}" + CRLF
      submission_post_request_body +=  "Content-Disposition: form-data; name=\"authenticity_token\"" + CRLF + CRLF
      submission_post_request_body +=  "#{auth_token}" + CRLF
    else
      submission_post_request_body = ""
    end
    # construct some submission request bodies
    Dir.glob(File.join(SUBMISSION_RES_DIR, "*")).each { |file|
      file_content = File.open(file).read
      submission_post_request_body += get_file_header(URI.encode(File.basename(file)), boundary)
      submission_post_request_body += file_content + CRLF + CRLF
    }
    submission_post_request_body +=  "--#{boundary}" + CRLF
    submission_post_request_body +=  "Content-Disposition: form-data; name=\"commit\"" + CRLF + CRLF
    submission_post_request_body +=  "Submit" + CRLF
    submission_post_request_body += "--#{boundary}--" + CRLF# epilogue

    # write submission post request to file
    File.open(File.join(HOME_REQUESTS, POST_DIR, SUBMISSION_DIR, login), "w") { |file|
      file.write(submission_post_request_body)
    }
    # write cookie file for login
    File.open(File.join(HOME_REQUESTS, BOUNDARY_DIR, login), "w") { |file|
      file.write(boundary + "\n")
    }
  end
end
