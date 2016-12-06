namespace :db do

  desc 'Create a single Instructor'
  task :admin => :environment do
    puts 'Populate database with Admins'
    [['a',    'admin', 'admin'], # Standard admin
     ['reid', 'Karen', 'Reid']]  # Reid
    .each do |admin|
      Admin.create(user_name: admin[0], first_name: admin[1], last_name: admin[2])
    end
  end

  desc 'Add TA users to the database'
  # this task depends on :environment and :seed
  task(:tas => :environment) do
        puts 'Populate database with TAs'
    [['c6conley', 'Mike',    'Conley'],
     ['c6gehwol', 'Severin', 'Gehwolf'],
     ['c9varoqu', 'Nelle',   'Varoquaux'],
     ['c9rada',   'Mark',    'Rada']]
        .each do |ta|
      Ta.create(user_name: ta[0], first_name: ta[1], last_name: ta[2])
    end
  end

  desc 'Add a local TestServer account'
  # this task depends on :environment and :seed
  task(:test_servers => :environment) do
    puts 'Populate database with TestServers'
    [[MarkusConfigurator::markus_ate_server_host, 'Test', 'Server1']]
        .each do |server|
      TestServer.create(user_name: server[0], first_name: server[1], last_name: server[2], hidden: true)
    end
  end

  desc 'Add student users to the database'
  # this task depends on :environment and :seed
  task(:users => :environment) do
    puts 'Populate database with Students'
    STUDENT_CSV = 'db/data/students.csv'
    if File.readable?(STUDENT_CSV)
      csv_students = File.new(STUDENT_CSV)
      User.upload_user_list(Student, csv_students, nil)
    end
  end
end