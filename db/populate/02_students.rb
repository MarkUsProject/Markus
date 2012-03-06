STUDENT_CSV = 'db/populate/students.csv'

if File.readable?(STUDENT_CSV)
  csv_students = File.new(STUDENT_CSV)
  User.upload_user_list(Student, csv_students, nil)
end
