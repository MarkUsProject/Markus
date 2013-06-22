require './api_wrapper.rb'
 
# Set the API Url and your auth/api key
MarkusRESTfulAPI.configure('http://localhost:3000/api/',
  'MzNjMDcwMDhjZjMzY2E0NjdhODM2YWRkZmFhZWVjOGE=')

user = MarkusRESTfulAPI::Users.get_by_username('c5anthei')
puts user.user_name

user2 = MarkusRESTfulAPI::Users.get_by_id(84)
puts user2.user_name

puts MarkusRESTfulAPI::Users.get_all_admins()
