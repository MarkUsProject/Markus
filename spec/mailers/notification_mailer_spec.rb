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
      expect(@mail.body.to_s).to include("#{@user.first_name} #{@user.last_name}")
    end

    it 'renders the disclaimer in the body of the email.' do
      expect(@mail.body.to_s).to include('This is an automated email. Please do not reply.')
    end

    it 'renders the assignment in the body of the email.' do
      expect(@mail.body.to_s).to include(@fake_assignment.short_identifier.to_s)
    end
  end

  describe 'release_spreadsheet_email' do
    before(:each) do
      @user = create(:student)
      @grade_entry_form = create(:grade_entry_form_with_data)
      @grade_entry_student = @grade_entry_form.grade_entry_students.find_or_create_by(user: @user)
      @mail = described_class.with(student: @grade_entry_student, form: @grade_entry_form)
                             .release_spreadsheet_email.deliver_now
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
      first_name = @grade_entry_student.user.first_name
      last_name = @grade_entry_student.user.last_name
      expect(@mail.body.to_s).to include("#{first_name} #{last_name}")
    end

    it 'renders the disclaimer in the body of the email.' do
      expect(@mail.body.to_s).to include('This is an automated email. Please do not reply.')
    end

    it 'renders the spreadsheet name in the body of the email.' do
      expect(@mail.body.to_s).to include(@grade_entry_form.short_identifier.to_s)
    end
  end

  describe 'grouping_invite_email' do
    before(:each) do
      @inviter = create(:student)
      @invited = create(:student)
      @fake_assignment = create(:assignment)
      @grouping = create(:grouping, assignment: @fake_assignment)
      @mail = described_class.with(invited: @invited, inviter: @inviter, grouping: @grouping)
                             .grouping_invite_email.deliver_now
    end

    it 'renders the subject' do
      subject_line = 'MarkUs Notification (' + Rails.configuration.course_name + ') You have been invited to a group!'
      expect(@mail.subject).to eq(subject_line)
    end

    it 'renders the receiver email' do
      expect(@mail.to).to eq([@invited.email])
    end

    it 'renders the sender email' do
      expect(@mail.from).to eq(['noreply@markus.com'])
    end

    it 'renders the inviter name in the body of the email.' do
      first_name = @inviter.first_name
      last_name = @inviter.last_name
      expect(@mail.body.to_s).to include("#{first_name} #{last_name}")
    end

    it 'renders the invitee name in the body of the email.' do
      first_name = @invited.first_name
      last_name = @invited.last_name
      expect(@mail.body.to_s).to include("#{first_name} #{last_name}")
    end

    it 'renders the disclaimer in the body of the email.' do
      expect(@mail.body.to_s).to include('This is an automated email. Please do not reply.')
    end
  end
end
