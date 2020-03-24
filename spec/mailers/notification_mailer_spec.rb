RSpec.describe NotificationMailer, type: :mailer do
  describe 'release_email' do
    before(:each) do
      @user = create(:student)
      @fake_assignment = create(:assignment)
      @grouping = create(:grouping, assignment: @fake_assignment)
      @submission = create(:submission, submission_version_used: true, grouping: @grouping)
      @grouping.reload
      @mail = described_class.with(user: @user, grouping: @grouping).release_email.deliver_now
    end

    it 'renders the subject' do
      subject_line = 'MarkUs Notification (' + Rails.configuration.course_name + ') Your marks for ' +
          @fake_assignment.short_identifier + ' have been released!'
      expect(@mail.subject).to eq(subject_line)
    end

    it 'renders the receiver email' do
      expect(@mail.to).to eq([@user.email])
    end

    it 'renders the sender email' do
      expect(@mail.from).to eq(['noreply@markus.com'])
    end

    it 'renders the student name in the body of the email.' do
      expect(@mail.body.to_s).to match("#{@user.first_name} #{@user.last_name}")
    end

    it 'renders the disclaimer in the body of the email.' do
      expect(@mail.body.to_s).to match('This is an automated email. Please do not reply.')
    end

    it 'renders the assignment in the body of the email.' do
      expect(@mail.body.to_s).to match(@fake_assignment.short_identifier.to_s)
    end
  end

  describe 'release_spreadsheet_email' do
    before(:each) do
      @user = create(:student)
      @grade_entry_student = create(:grade_entry_student, user: @user)
      @grade_entry_form = create(:grade_entry_form_with_data)
      @mail = described_class.with(student: @grade_entry_student, form: @grade_entry_form).release_email.deliver_now
    end

    it 'renders the subject' do
      subject_line = 'MarkUs Notification (' + Rails.configuration.course_name + ') Your marks for ' +
      @grade_entry_form.short_identifier + ' have been released!'
      expect(@mail.subject).to eq(subject_line)
    end

    it 'renders the receiver email' do
      expect(@mail.to).to eq([@grade_entry_student.user.email])
    end

    it 'renders the sender email' do
      expect(@mail.from).to eq(['noreply@markus.com'])
    end

    it 'renders the student name in the body of the email.' do
      expect(@mail.body.to_s).to match("#{@grade_entry_student.user.first_name} #{@grade_entry_student.user.last_name}")
    end

    it 'renders the disclaimer in the body of the email.' do
      expect(@mail.body.to_s).to match('This is an automated email. Please do not reply.')
    end

    it 'renders the assignment in the body of the email.' do
      expect(@mail.body.to_s).to match(@grade_entry_form.short_identifier.to_s)
    end
  end
end
