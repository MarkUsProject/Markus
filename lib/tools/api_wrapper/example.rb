require './api_wrapper.rb'

# RUNNING THIS EXAMPLE
# cd lib/tools/api_wrapper
# bundle install
# bundle exec ruby example.rb

# CONFIGURATION

# Set the API Url and your auth/api key
MarkusRESTfulAPI.configure('http://localhost:3000/api',
  'YmE1ODMzYWY5NjY3ZjcyNTVhYmI5YjY1ZGFmNzM4ZTY=')

# USERS

# Get a user by their username
puts 'Get a user by their username, where username is c5anthei'
user = MarkusRESTfulAPI::Users.get_by_user_name('c5anthei')
user.each { |key, val| puts "#{key}: #{val}"}
puts "\n"

# Getting a user by their id
puts 'Get a user by their id, where id is 84'
user = MarkusRESTfulAPI::Users.get_by_id(84)
user.each { |key, val| puts "#{key}: #{val}"}
puts "\n"

# Getting all admin users. Returns an array of objects of class User
puts 'Getting all admins'
admins = MarkusRESTfulAPI::Users.get_all_admins()
admins.each do |admin|
  puts "id: #{admin['id']}"
  puts "user_name: #{admin['user_name']}"
  puts "first_name: #{admin['first_name']}"
end
puts "\n"

# Example of getting a user that doesn't exist
puts "Getting a user that doesn't exist, printing the exception"
begin
  user = MarkusRESTfulAPI::Users.get_by_id(84999999)
rescue Exception => e
  # Outputs 'No user exists with that id'
  puts e.message
end
puts "\n"

# Creating a new ta with a generated user_name
puts 'Creating a new ta account and printing the result'
attributes = { 'user_name' => "User#{rand(10000)}", 'first_name' => 'Dan',
               'last_name' => 'Test', 'type' => 'ta' }
user = MarkusRESTfulAPI::Users.create(attributes)
user.each { |key, val| puts "#{key}: #{val}"}
puts "\n"

# Update the ta we created
puts "Updating the ta's name to Daniel and printing the result"
attributes = { 'first_name' => 'Daniel' }
MarkusRESTfulAPI::Users.update(user['id'], attributes)
user = MarkusRESTfulAPI::Users.get_by_id(user['id'])
user.each { |key, val| puts "#{key}: #{val}"}
puts "\n"
