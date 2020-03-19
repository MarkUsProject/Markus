RSpec.describe NotificationMailer, type: :mailer do
  describe 'release_email' do
    let(:user) { create(:user) }
    let(:fake_assignment) { create(:user) }
    let(:grouping) { create(:grouping, assignment: fake_assignment) }
    let(:mail) { described_class.with(user: user, grouping: grouping).release_email.deliver_now }

    it 'renders the subject' do
      subject_line = 'MarkUs Notification (' + Rails.configuration.course_name + ') Your marks for A2 have released!'
      expect(mail.subject).to eq(subject_line)
    end

    it 'renders the receiver email' do
      puts mail.body.to_s
      expect(mail.to).to eq([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['noreply@markus.com'])
    end

    # not sure what these do
    it 'renders the student name in the body of the email.' do
      expect(mail.body.to_s).to match(/"#{user.first_name} #{user.last_name}"/)
    end

    it 'renders the disclaimer in the body of the email.' do
      expect(mail.body.to_s).to match(/This is an automated email. Please do not reply./)
    end

    it 'renders the assignment in the body of the email.' do
      expect(mail.body.to_s).to match("#{fake_assignment.short_identifier}")
    end
  end
end
