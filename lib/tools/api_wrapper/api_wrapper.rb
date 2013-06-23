require 'httparty'
require 'singleton'

class MarkusRESTfulAPI
  attr_accessor :config

  # Stores the api_url and auth_key for later use
  def MarkusRESTfulAPI.configure(api_url, auth_key)
    @@auth_key = auth_key
    api_url = "#{api_url}/" if api_url[-1, 1] != '/'
    @@api_url = api_url
  end

  # Makes a GET request to provided URL while supplying the authorization 
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

  # A singleton that allows us to retrieve user(s). It enables us to retrieve 
  # users by user_name, id, first_name, last_name, as well as type
  class Users < MarkusRESTfulAPI
    include Singleton

    def self.get_by_user_name(user_name)
      response = self.get("users.json?filter=user_name:#{user_name}")
      User.new(response['users']['user'])
    end

    def self.get_by_id(id)
      response = self.get("users/#{id}.json")
      User.new(response['users'])
    end

    def self.get_all_by_first_name(first_name)
      response = self.get("users.json?filter=first_name:#{first_name}")

      users = []
      response['users']['user'].each do |user|
        users << User.new(user)
      end

      users
    end

    def self.get_all_admins()
      response = self.get('users.json?filter=type:admin')

      users = []
      response['users']['user'].each do |user|
        users << User.new(user)
      end

      users
    end

    def self.get_all_tas()
      response = self.get('users.json?filter=type:ta')

      users = []
      response['users']['user'].each do |user|
        users << User.new(user)
      end

      users
    end

    def self.get_all_students()
      response = self.get('users.json?filter=type:student')

      users = []
      response['users']['user'].each do |user|
        users << User.new(user)
      end

      users
    end

    def self.create(attributes)
      url = 'users.json'
      response = self.post(url, attributes)
      # Now that the user's been created, return that user
      user = self.get_by_user_name(attributes['user_name'])
    end
  end # Users

  # Represents a single user returned by the API
  class User
    attr_accessor :id, :user_name, :type, :first_name, :last_name, :notes_count,
                  :grace_credits, :section_name

    def initialize(attributes)
      attributes.each do |key, value|
        instance_variable_set("@#{key.to_sym}", value)
      end
    end
  end # User

end # MarkusRESTfulAPI

