require './api_wrapper.rb'

# RUNNING THIS EXAMPLE
# cd lib/tools/api_wrapper
# bundle install
# bundle exec ruby example.rb

# CONFIGURATION

# Set the API Url and your auth/api key
MarkusRESTfulAPI.configure('http://localhost:3000/api',
  'YmE1ODMzYWY5NjY3ZjcyNTVhYmI5YjY1ZGFmNzM4ZTY=')

# HELPERS FOR PRINTING RESPONSES
# You can simply iterate over their key val pairs

def print_attributes(object, keys)
  keys.each do |key|
    puts "#{key}: #{object[key]}"
  end
  puts "\n"
end

def print_all_attributes(object)
  object.each { |key, val| puts "#{key}: #{val}" }
  puts "\n"
end

# USERS

# Get a user by their username
puts 'Get a user by their username, where username is c5anthei'
user = MarkusRESTfulAPI::Users.get_by_user_name('c5anthei')
print_all_attributes(user)

# Getting a user by their id
puts 'Get a user by their id, where id is 84'
user = MarkusRESTfulAPI::Users.get_by_id(84)
print_all_attributes(user)

# Getting all admin users
puts 'Getting all admins'
admins = MarkusRESTfulAPI::Users.get_all_admins()
admins.each do |admin|
  print_attributes(admin, ['id', 'user_name', 'first_name'])
end

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
print_all_attributes(user)

# Update the ta we created
puts "Updating the ta's name to Daniel and printing the result"
attributes = { 'first_name' => 'Daniel' }
user = MarkusRESTfulAPI::Users.update(user['id'], attributes)
print_all_attributes(user)

# ASSIGNMENTS

# Get an assignment by its short_identifier
puts 'Get an assignment by its short_identifier, where short_identifier is A1'
assignment = MarkusRESTfulAPI::Assignments.get_by_short_identifier('A1')
print_all_attributes(assignment)

# Getting an assignment by id id
puts 'Get an assignment by its id, where id is 2'
assignment = MarkusRESTfulAPI::Assignments.get_by_id(2)
print_all_attributes(assignment)

# Getting all assignments
puts 'Getting all assignments'
assignments = MarkusRESTfulAPI::Assignments.get_all()
assignments.each do |assignment|
  print_attributes(assignment, ['id', 'short_identifier', 'description'])
end

# Creating a new assignment with a generated short_identifier
puts 'Creating a new assignment and printing the result'
attributes = { 'short_identifier' => "AS#{rand(10000)}", 'description' => 'Test',
               'due_date' => '2013-08-22T00:16:59-04:00' }
assignment = MarkusRESTfulAPI::Assignments.create(attributes)
print_attributes(assignment, ['id', 'short_identifier', 'description'])

# Update the assignment we created
puts "Updating the assignment's description to 'Example' and printing the result"
attributes = { 'description' => 'Example' }
assignment = MarkusRESTfulAPI::Assignments.update(assignment['id'], attributes)
print_attributes(assignment, ['id', 'short_identifier', 'description'])

# GROUPS

assignment_id = 1

# Getting a group by id
puts 'Get a group by its id'
group = MarkusRESTfulAPI::Groups.get_by_id(assignment_id, 2)
print_attributes(group, ['id', 'group_name'])

# Getting a group by group_name
puts 'Get a group by its group_name'
group = MarkusRESTfulAPI::Groups.get_by_group_name(assignment_id, 'c5granad')
print_attributes(group, ['id', 'group_name'])

# Getting all groups
puts 'Getting all groups for an assignment'
groups = MarkusRESTfulAPI::Groups.get_all(assignment_id)
groups.each do |group|
  print_attributes(group, ['id', 'group_name'])
end

# Downloading a group's submission
puts "Download a group's submission"
group_id = 2
file_name = MarkusRESTfulAPI::Groups.download_submission(assignment_id, group_id)
puts "Downloaded to #{file_name}"
