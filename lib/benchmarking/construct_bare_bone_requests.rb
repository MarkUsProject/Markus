# Constructs basic login/submission post requests (assumes protect_from_forgery
# is turned off)

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
    # get cookie
    cookie = res.response['set-cookie']
    cookie = cookie[0..(cookie.index(";")-1)]

    post_request = "user_login=#{login}&user_password=somepassword"
    post_request += "&commit=Log+in" + CRLF

    # construct post-body-file for login
    File.open(File.join(HOME_REQUESTS, POST_DIR, LOGIN_DIR, login), "w") { |file|
      file.write(post_request)
    }
    # write cookie file for login
    File.open(File.join(HOME_REQUESTS, COOKIES_DIR, login), "w") { |file|
      file.write(cookie + "\n")
    }

    # submissions post requests

    boundary = Digest::MD5.hexdigest(Time.now.to_f.to_s)
    boundary = "---------------------------" + boundary
    #boundary = Time.now.to_f.to_s.gsub(/\./, "")

    submission_post_request_body = ""
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
