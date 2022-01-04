namespace :markus do
  desc 'Resets the API key for Instructors and TAs'
  task(reset_api_keys: :environment) do
    print('Resetting API keys for Instructors and TAs...')
    users = Ta.all + Instructor.all
    users.each do |user|
      unless user.api_key.nil?
        user.reset_api_key
      end
    end
    puts(' done!')
  end
end
