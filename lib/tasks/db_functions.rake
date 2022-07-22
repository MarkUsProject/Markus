namespace :db do
  task functions: :environment do
    ActiveRecord::Base.connection.execute(File.read(Rails.root.join('db/functions.sql')))
  end
end
