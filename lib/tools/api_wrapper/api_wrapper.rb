require 'httparty'
require 'singleton'
require 'uri'

class MarkusRESTfulAPI

  # Stores the api_url and auth_key for later use
  def MarkusRESTfulAPI.configure(api_url, auth_key)
    @@auth_key = auth_key
    api_url = "#{api_url}/" if api_url[-1, 1] != '/'
    @@api_url = api_url
  end

  # Makes a GET request to the provided URL while supplying the authorization
  # header, and raising an exception on failure
  def MarkusRESTfulAPI.get(url)
    response = HTTParty.get(@@api_url + url, :headers =>
      { 'Authorization' => "MarkUsAuth #{@@auth_key}", 'Accept' => 'application/json' })
    raise "#{response['code']}: #{response['description']}" unless response.success?

    response
  end

  # Makes a POST request to the provided URL, along with the supplied POST data.
  # Also uses the authorization header, and raises an exception on failure
  def MarkusRESTfulAPI.post(url, query)
    options = { :headers => { 'Authorization' => "MarkUsAuth #{@@auth_key}",
                'Accept' => 'application/json' }, :body => query }
    response = HTTParty.post(@@api_url + url, options)
    raise "#{response['code']}: #{response['description']}" unless response.success?

    response
  end

  # Makes a PUT request to the provided URL, along with the supplied data.
  # Also uses the authorization header, and raises an exception on failure
  def MarkusRESTfulAPI.put(url, query)
    options = { :headers => { 'Authorization' => "MarkUsAuth #{@@auth_key}",
                'Accept' => 'application/json' }, :body => query }
    response = HTTParty.put(@@api_url + url, options)
    raise "#{response['code']}: #{response['description']}" unless response.success?

    response
  end

  # Makes a DELETE request to the provided URL while supplying the authorization
  # header, and raising an exception on failure
  def MarkusRESTfulAPI.delete(url)
    response = HTTParty.delete(@@api_url + url, :headers =>
      { 'Authorization' => "MarkUsAuth #{@@auth_key}", 'Accept' => 'application/json' })
    puts response
    raise "#{response['code']}: #{response['description']}" unless response.success?

    response
  end

  # A singleton that allows us to get and update user(s)
  class Users < MarkusRESTfulAPI

    include Singleton

    def self.get_by_user_name(user_name)
      self.get("users.json?filter=user_name:#{user_name}")[0]
    end

    def self.get_by_id(id)
      self.get("users/#{id}.json")
    end

    def self.get_all_by_first_name(first_name)
      self.get("users.json?filter=first_name:#{first_name}")
    end

    def self.get_all_admins()
      self.get('users.json?filter=type:admin')
    end

    def self.get_all_tas()
      self.get('users.json?filter=type:ta')
    end

    def self.get_all_students()
      self.get('users.json?filter=type:student')
    end

    def self.create(attributes)
      url = 'users.json'
      response = self.post(url, attributes)

      self.get_by_user_name(attributes['user_name'])
    end

    def self.update(id, attributes)
      attributes.delete('id')
      url = "users/#{id}.json"
      self.put(url, attributes)

      self.get_by_id(id)
    end

  end # Users

  # A singleton that allows us to get and update assignment(s)
  class Assignments < MarkusRESTfulAPI

    include Singleton

    def self.get_by_id(id)
      self.get("assignments/#{id}.json")
    end

    def self.get_by_short_identifier(short_identifier)
      self.get("assignments.json?filter=short_identifier:#{short_identifier}")[0]
    end

    def self.get_all()
      self.get('assignments.json')
    end

    def self.create(attributes)
      url = 'assignments.json'
      response = self.post(url, attributes)

      self.get_by_short_identifier(attributes['short_identifier'])
    end

    def self.update(id, attributes)
      attributes.delete('id')
      url = "assignments/#{id}.json"
      self.put(url, attributes)

      self.get_by_id(id)
    end

  end # Assignments

  # A singleton that allows us to get groups and their submissions
  class Groups < MarkusRESTfulAPI

    include Singleton

    def self.get_by_id(assignment_id, id)
      self.get("assignments/#{assignment_id}/groups/#{id}.json")
    end

    def self.get_by_group_name(assignment_id, group_name)
      self.get("assignments/#{assignment_id}/groups.json?" +
        "filter=group_name:#{group_name}")[0]
    end

    def self.get_all(assignment_id)
      self.get("assignments/#{assignment_id}/groups.json")
    end

    # Downloads the file to the current dir, assignment_groupname.zip
    # Returns the file_name
    def self.download_submission(assignment_id, id)
      path = "assignments/#{assignment_id}/groups/#{id}/submission_downloads"
      uri = URI(@@api_url + path)

      short_identifier = self.get("assignments/#{id}.json")['short_identifier']
      group = self.get("assignments/#{assignment_id}/groups/#{id}.json")['group_name']
      file_name = "#{short_identifier}_#{group}.zip"

      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri.request_uri
        request.add_field 'Authorization', "MarkUsAuth #{@@auth_key}"

        http.request request do |response|
          open file_name, 'w' do |io|
            response.read_body { |chunk| io.write chunk }
          end
        end
      end

      file_name
    end

  end # Groups

end # MarkusRESTfulAPI
