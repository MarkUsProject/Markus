require 'erb'

RSpec.describe NotificationMailer do
  include ERB::Util

  RSpec.shared_examples 'an email' do
    it 'renders the disclaimer in the body of the email.' do
      expect(mail.body.to_s).to include('This is an automated email. Please do not reply.')
    end

    it 'renders the sender email' do
      expect(mail.from).to eq(['noreply@markus.com'])
    end

    it 'renders the recipient greeting in the body of the email.' do
      display_name = recipient.display_name
      expect(mail.body.to_s).to include(h("Hello #{display_name},"))
    end

    it 'renders the recipient email' do
      expect(mail.to).to eq([recipient.email])
    end

    it 'renders the relevant link correctly' do
      expect(mail.body.to_s).to include(relevant_link)
    end

    it 'renders the link to unsubscribe' do
      expect(mail.body.to_s).to include(settings_users_url)
    end
  end

  describe 'release_email' do
    let(:recipient) { create(:student) }
    let(:submission) { create(:version_used_submission) }
    let(:relevant_link) do
      view_marks_course_result_url(submission.course, submission.grouping.current_result)
    end
    let(:mail) do
      submission.grouping.reload
      NotificationMailer.with(user: recipient, grouping: submission.grouping).release_email.deliver_now
    end

    it 'renders the subject' do
      subject_line = "MarkUs Notification (#{submission.course.name}) Your marks for " \
                     "#{submission.assignment.short_identifier} have been released!"
      expect(mail.subject).to eq(subject_line)
    end

    it 'renders the assignment in the body of the email.' do
      expect(mail.body.to_s).to include(submission.assignment.short_identifier.to_s)
    end

    it_behaves_like 'an email'
  end

  describe 'release_spreadsheet_email' do
    let(:recipient) { create(:student) }
    let(:grade_entry_form) { create(:grade_entry_form_with_data) }
    let(:relevant_link) { student_interface_course_grade_entry_form_url(grade_entry_form.course, grade_entry_form) }
    let(:mail) do
      NotificationMailer.with(student: grade_entry_form.grade_entry_students.find_or_create_by(role: recipient),
                              form: grade_entry_form,
                              course: grade_entry_form.course)
                        .release_spreadsheet_email
                        .deliver_now
    end

    it 'renders the subject' do
      subject_line = "MarkUs Notification (#{grade_entry_form.course.name}) Your marks for " \
                     "#{grade_entry_form.short_identifier} have been released!"
      expect(mail.subject).to eq(subject_line)
    end

    it 'renders the spreadsheet name in the body of the email.' do
      expect(mail.body.to_s).to include(grade_entry_form.short_identifier.to_s)
    end

    it_behaves_like 'an email'
  end

  describe 'grouping_invite_email' do
    let(:inviter) { create(:student) }
    let(:recipient) { create(:student) }
    let(:grouping) { create(:grouping) }
    let(:relevant_link) { course_assignment_url(grouping.course, grouping.assignment) }
    let(:mail) do
      NotificationMailer.with(invited: recipient, inviter: inviter, grouping: grouping)
                        .grouping_invite_email
                        .deliver_now
    end

    it 'renders the subject' do
      subject_line = "MarkUs Notification (#{grouping.course.name}) You have been invited to a group!"
      expect(mail.subject).to eq(subject_line)
    end

    it 'renders the inviter name in the body of the email.' do
      display_name = inviter.display_name
      expect(mail.body.to_s).to include(h(display_name))
    end

    it_behaves_like 'an email'
  end
end
