# Instructor user for a given course.
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
class Instructor < Role
  after_create { Repository.get_class.update_permissions }
  after_destroy { Repository.get_class.update_permissions }
  validate :associated_user_is_an_end_user, unless: -> { self.admin_role? }

  has_many :memberships, dependent: :delete_all, foreign_key: 'role_id', inverse_of: :role

  has_many :annotation_texts, dependent: :nullify, inverse_of: :creator, foreign_key: :creator_id
  has_many :annotations, dependent: :nullify, inverse_of: :creator, foreign_key: :creator_id
  has_many :notes, dependent: :restrict_with_exception, inverse_of: :role, foreign_key: :creator_id
  has_many :tags, dependent: :restrict_with_exception, foreign_key: :role_id, inverse_of: :role
  has_many :split_pdf_logs, dependent: :restrict_with_exception, foreign_key: :role_id, inverse_of: :role
end
