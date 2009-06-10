namespace :olm do
  desc "Create a single Administrator with username a"
  task(:admin => :environment) do
    puts "Creating Administrator with username 'a'..."
    a = Admin.new({:user_name => 'a', :first_name => 'admin', :last_name => 'admin'})
    a.save
  end
end
