describe 'Flash messages stored in the session cookie' do
  let(:instructor) { create(:instructor) }
  let(:assignment) { create(:assignment, course: instructor.course) }

  # Disable CSRF protection so that the CSV upload form can be posted directly
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = false
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  before do
    post '/', params: { user_login: instructor.user_name, user_password: 'a' }
  end

  it 'does not overflow the session cookie when a CSV upload has many long invalid rows' do
    rows = Array.new(MarkusCsv::MAX_INVALID_LINES) do |i|
      "no_such_group_#{i},#{Array.new(30) { |j| "grader_name_#{j}" }.join(',')}"
    end
    file = Rack::Test::UploadedFile.new(StringIO.new(rows.join("\n")), 'text/csv', original_filename: 'map.csv')

    post "/courses/#{instructor.course.id}/assignments/#{assignment.id}/graders/upload",
         params: { upload_file: file, groupings: true }

    expect(response).to redirect_to(course_assignment_graders_path(instructor.course, assignment))
  end
end
