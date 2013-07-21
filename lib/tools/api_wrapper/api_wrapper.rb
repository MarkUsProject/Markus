require 'httparty'
require 'singleton'

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
      { 'Authorization' => "MarkUsAuth #{@@auth_key}" })
    raise response['rsp']['__content__'] unless response.success?

    response
  end

  # Makes a POST request to the provided URL, along with the supplied POST data.
  # Also uses the authorization header, and raises an exception on failure
  def MarkusRESTfulAPI.post(url, query)
    options = { :headers => { 'Authorization' => "MarkUsAuth #{@@auth_key}" },
                :body => query }
    response = HTTParty.post(@@api_url + url, options)
    raise response['rsp']['__content__'] unless response.success?

    response
  end

  # Makes a PUT request to the provided URL, along with the supplied data.
  # Also uses the authorization header, and raises an exception on failure
  def MarkusRESTfulAPI.put(url, query)
    options = { :headers => { 'Authorization' => "MarkUsAuth #{@@auth_key}" },
                :body => query }
    response = HTTParty.put(@@api_url + url, options)
    raise response['rsp']['__content__'] unless response.success?

    response
  end

  # Makes a DELETE request to the provided URL while supplying the authorization 
  # header, and raising an exception on failure
  def MarkusRESTfulAPI.delete(url)
    response = HTTParty.delete(@@api_url + url, :headers => 
      { 'Authorization' => "MarkUsAuth #{@@auth_key}" })
    puts response
    raise response['rsp']['__content__'] unless response.success?

    response
  end

  # A singleton that allows us to get and update user(s)
  class Users < MarkusRESTfulAPI

    include Singleton

    def self.get_by_user_name(user_name)
      self.get("users.json?filter=user_name:#{user_name}")['users']['user']
    end

    def self.get_by_id(id)
      self.get("users/#{id}.json")['users']
    end

    def self.get_all_by_first_name(first_name)
      self.get("users.json?filter=first_name:#{first_name}")['users']['user']
    end

    def self.get_all_admins()
      self.get('users.json?filter=type:admin')['users']['user']
    end

    def self.get_all_tas()
      self.get('users.json?filter=type:ta')['users']['user']
    end

    def self.get_all_students()
      self.get('users.json?filter=type:student')['users']['user']
    end

    def self.create(attributes)
      url = 'users.json'
      response = self.post(url, attributes)
      self.get_by_user_name(attributes['user_name'])
    end

    def self.update(id, attributes)
      attributes.delete('id')
      url = "users/#{id}.json"
      Users.put(url, attributes)
      return
    end

  end # Users

end # MarkusRESTfulAPI

