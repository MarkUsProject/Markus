namespace :markus do
  task :add_roles, [:roles_file] => :environment do |_task, args|
    columns = [:course_name, :role_type] + Student::CSV_ORDER
    if args[:roles_file].nil?
      puts 'Usage: this rake task takes one argument: a path to a csv file containing the following fields:'
      puts "\n\t#{columns.map(&:to_s).map(&:humanize).join(', ')}"
      puts "\nNote:\tSection name, Id number, and Email are optional fields"
      puts "\tRole Type should be one of: student, ta, instructor"
      exit
    end

    MarkusCsv.parse(File.read(args[:roles_file])) do |row|
      next if row.blank?
      data = columns.zip(row).to_h
      user = EndUser.find_or_create_by!(user_name: data[:user_name]) do |end_user|
        puts "Creating User with username = #{data[:user_name]}"
        end_user.first_name = data[:first_name]
        end_user.last_name = data[:last_name]
        end_user.id_number = data[:id_number]
        end_user.email = data[:email]
      end
      course = Course.find_by(name: data[:course_name])
      course.roles.find_or_create_by!(user: user, type: data[:role_type].capitalize) do |role|
        puts "Creating #{data[:role_type]} role in course with name = #{course.name} " \
             "for user with username = #{data[:user_name]}"
        if data[:section_name]
          section = course.sections.find_by(name: data[:section_name])
          role.section = section if section
        end
      end
    end
  end
end
