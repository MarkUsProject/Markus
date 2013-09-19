namespace :markus do

  desc "Resets the API key for Admins and TAs"
  task(:reset_api_keys => :environment) do
    print("Resetting API keys for Admins and TAs...")
    users = Ta.all + Admin.all
    users.each do |user|
      if !user.api_key.nil?
	user.reset_api_key
      end
    end
    puts(" done!")
  end

end
