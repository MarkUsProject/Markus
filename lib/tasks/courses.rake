namespace :db do
  desc 'Create courses'
  task :courses => :environment do
    Course.create!(name: 'csc108', is_hidden: false, display_name: 'csc108 Fall 2021')
  end
end
