require 'httparty'
require 'singleton'

class MarkusRESTfulAPI
  include HTTParty
  attr_accessor :config

  # Stores the api_url and auth_key for later use
  def MarkusRESTfulAPI.configure(api_url, auth_key)
    @@api_url = api_url
    @@auth_key = auth_key
  end

  # A singleton that allows us to retrieve user(s)
  class Users < MarkusRESTfulAPI
    include Singleton

    def self.get_by_username(username)
      response = self.get("#{@@api_url}/users.json?filter=user_name:#{username}",
        :headers => {'Authorization' => "MarkUsAuth #{@@auth_key}"})
      raise response.response unless response.success?
      User.new(response['users']['user'])
    end

    def self.get_by_id(id)
      response = self.get("#{@@api_url}/users/#{id}.json",
        :headers => {'Authorization' => "MarkUsAuth #{@@auth_key}"})
      raise response.response unless response.success?
      User.new(response['users'])
    end

    def self.get_all_by_first_name(first_name)
      response = self.get("#{@@api_url}/users.json?filter=first_name:#{first_name}",
        :headers => {'Authorization' => "MarkUsAuth #{@@auth_key}"})
      raise response.response unless response.success?

      users = []
      response['users']['user'].each do |user|
        users << User.new(user)
      end
    end

    def self.get_all_admins()
      response = self.get("#{@@api_url}/users.json?filter=type:admin",
        :headers => {'Authorization' => "MarkUsAuth #{@@auth_key}"})
      raise response.response unless response.success?

      users = []
      response['users']['user'].each do |user|
        users << User.new(user)
      end
    end

    def self.get_all_tas()
      response = self.get("#{@@api_url}/users.json?filter=type:ta",
        :headers => {'Authorization' => "MarkUsAuth #{@@auth_key}"})
      raise response.response unless response.success?

      users = []
      response['users']['user'].each do |user|
        users << User.new(user)
      end
    end

    def self.get_all_students()
      response = self.get("#{@@api_url}/users.json?filter=type:student",
        :headers => {'Authorization' => "MarkUsAuth #{@@auth_key}"})
      raise response.response unless response.success?

      users = []
      response['users']['user'].each do |user|
        users << User.new(user)
      end
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

