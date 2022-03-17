namespace :db do
  task admin: :environment do
    user = AdminUser.find_or_create
    puts user.api_key
    [%w[admin test admin]].each do |admin|
      a = AdminUser.create!(user_name: admin[0],
                            first_name: admin[1],
                            last_name: admin[2])
      a.reset_api_key
    end
  end

  desc 'Create a single Instructor'
  task instructor: :environment do
    puts 'Populate database with Instructors'
    [%w[instructor test instructor],
     %w[reid Karen Reid]].each do |instructor|
      Instructor.create!(course: Course.first, end_user_attributes: { user_name: instructor[0],
                                                                      first_name: instructor[1],
                                                                      last_name: instructor[2] })
    end
  end

  desc 'Add TA users to the database'
  # this task depends on :environment and :seed
  task tas: :environment do
    puts 'Populate database with TAs'
    [%w[c6conley Mike Conley],
     %w[c6gehwol Severin Gehwolf],
     %w[c9varoqu Nelle Varoquaux],
     %w[c9rada Mark Rada]].each do |ta|
      Ta.create!(course: Course.first, end_user_attributes: { user_name: ta[0], first_name: ta[1], last_name: ta[2] })
    end
  end

  task student_users: :environment do
    puts 'Populate database with users'
    STUDENT_CSV = 'db/data/students.csv'.freeze
    if File.readable?(STUDENT_CSV)
      i = 0
      File.open(STUDENT_CSV) do |data|
        MarkusCsv.parse(data.read, skip_blanks: true, row_sep: :auto) do |row|
          user_name, first_name, last_name = row
          next if user_name.blank? || first_name.blank? || last_name.blank?
          first_name_email = first_name.downcase.gsub(/\s+/, '')
          last_name_email = last_name.downcase.gsub(/\s+/, '')
          i += rand(10 ** 7)
          EndUser.create!(user_name: user_name,
                          first_name: first_name,
                          last_name: last_name,
                          id_number: format('%010d', i),
                          email: "#{first_name_email}.#{last_name_email}@example.com")
        end
      end
    end
  end

  desc 'Add student users to the database'
  # this task depends on :environment and :seed
  task students: :environment do
    puts 'Populate database with Students'
    STUDENT_CSV = 'db/data/students.csv'.freeze
    course = Course.first
    course.sections.create(name: :LEC0101)
    course.sections.create(name: :LEC0201)
    if File.readable?(STUDENT_CSV)
      File.open(STUDENT_CSV) do |csv_students|
        UploadRolesJob.perform_now(Student, course, csv_students.read, nil)
      end
    end
    Student.find_each do |student|
      student.update(grace_credits: 5)
    end
  end
end
