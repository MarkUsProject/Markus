require 'erb'

RSpec.describe NotificationMailer, type: :mailer do
  include ERB::Util
  RSpec.shared_examples 'an email' do
    it 'renders the disclaimer in the body of the email.' do
      expect(mail.body.to_s).to include('This is an automated email. Please do not reply.')
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['noreply@markus.com'])
    end

    it 'renders the recipient greeting in the body of the email.' do
      first_name = recipient.first_name
      last_name = recipient.last_name
      expect(mail.body.to_s).to include(h("Hello #{first_name} #{last_name},"))
    end

    it 'renders the recipient email' do
      expect(mail.to).to eq([recipient.email])
    end
  end

  describe 'release_email' do
    let(:recipient) { create(:student) }
    let(:submission) { create(:version_used_submission) }
    let(:mail) do
      submission.grouping.reload
      described_class.with(user: recipient, grouping: submission.grouping).release_email.deliver_now
    end

    it 'renders the subject' do
      subject_line = 'MarkUs Notification (' + Rails.configuration.course_name + ') Your marks for ' +
          submission.assignment.short_identifier + ' have been released!'
      expect(mail.subject).to eq(subject_line)
    end

    it 'renders the assignment in the body of the email.' do
      expect(mail.body.to_s).to include(submission.assignment.short_identifier.to_s)
    end

    include_examples 'an email'
  end

  describe 'release_spreadsheet_email' do
    let(:recipient) { create(:student) }
    let(:grade_entry_form) { create(:grade_entry_form_with_data) }
    let(:mail) do
      described_class.with(student: grade_entry_form.grade_entry_students.find_or_create_by(user: recipient),
                           form: grade_entry_form)
                     .release_spreadsheet_email
                     .deliver_now
    end

    it 'renders the subject' do
      subject_line = 'MarkUs Notification (' + Rails.configuration.course_name + ') Your marks for ' +
      grade_entry_form.short_identifier + ' have been released!'
      expect(mail.subject).to eq(subject_line)
    end

    it 'renders the spreadsheet name in the body of the email.' do
      expect(mail.body.to_s).to include(grade_entry_form.short_identifier.to_s)
    end

    include_examples 'an email'
  end

  describe 'grouping_invite_email' do
    let(:inviter) { create(:student) }
    let(:recipient) { create(:student) }
    let(:grouping) { create(:grouping) }
    let(:mail) do
      described_class.with(invited: recipient, inviter: inviter, grouping: grouping)
                     .grouping_invite_email
                     .deliver_now
    end

    it 'renders the subject' do
      subject_line = 'MarkUs Notification (' + Rails.configuration.course_name + ') You have been invited to a group!'
      expect(mail.subject).to eq(subject_line)
    end

    it 'renders the inviter name in the body of the email.' do
      first_name = inviter.first_name
      last_name = inviter.last_name
      expect(mail.body.to_s).to include(h("#{first_name} #{last_name}"))
    end

    include_examples 'an email'
  end
end
