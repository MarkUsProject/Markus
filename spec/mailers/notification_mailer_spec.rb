require 'rails_helper'
RSpec.describe NotificationMailer, type: :mailer do
  describe 'release_email' do
    let(:user) { mock_model User, first_name: 'Ignas', last_name: 'Panero Armoska', email: 'ignaspan@gmail.com' }
    let(:fake_assignment) { mock_model Assignment, short_identifier: 'A2'}
    let(:grouping) { mock_model Grouping, assignment: fake_assignment}
    let(:mail) { described_class.with(user: user, grouping: grouping).release_email.deliver_now }

    it 'renders the subject' do
      expect(mail.subject).to eq('MarkUs Notification NOT SURE FOR COURSE Your marks for A2 have released!')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['noreply@markus.com'])
    end

    # not sure what these do
    it 'assigns @name' do
      expect(mail.body.encoded).to match(user.name)
    end

    it 'assigns @confirmation_url' do
      expect(mail.body.encoded)
          .to match("http://aplication_url/#{user.id}/confirmation")
    end
  end
end
