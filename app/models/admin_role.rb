# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: roles
#
#  id                      :bigint           not null, primary key
#  grace_credits           :integer          default(0), not null
#  hidden                  :boolean          default(FALSE), not null
#  receives_invite_emails  :boolean          default(FALSE), not null
#  receives_results_emails :boolean          default(FALSE), not null
#  type                    :string           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  course_id               :bigint           not null
#  section_id              :bigint
#  user_id                 :bigint           not null
#
# Indexes
#
#  index_roles_on_course_id              (course_id)
#  index_roles_on_section_id             (section_id)
#  index_roles_on_user_id                (user_id)
#  index_roles_on_user_id_and_course_id  (user_id,course_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (course_id => courses.id)
#  fk_rails_...  (section_id => sections.id)
#  fk_rails_...  (user_id => users.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class AdminRole < Instructor
  validate :associated_user_is_an_admin

  def associated_user_is_an_admin
    unless self.user.nil? || self.user.admin_user?
      errors.add(:base, :must_be_admin)
    end
  end
end
