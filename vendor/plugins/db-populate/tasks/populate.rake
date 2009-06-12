namespace :db do
  
  desc "Loads initial database models for the current environment."
  task :populate => :environment do
    require File.join(File.dirname(__FILE__), '/../lib', 'create_or_update')
    Dir[File.join(RAILS_ROOT, 'db', 'populate', '*.rb')].sort.each do |fixture| 
      load fixture 
      puts "Loaded #{fixture}"
    end
    Dir[File.join(RAILS_ROOT, 'db', 'populate', RAILS_ENV, '*.rb')].sort.each do |fixture| 
      load fixture 
      puts "Loaded #{fixture}"
    end
  end
  
  desc "Runs migrations and then loads seed data"
  task :migrate_and_populate => [ 'db:migrate', 'db:populate' ]

  task :migrate_and_load => [ 'db:migrate', 'db:populate' ]
  
end