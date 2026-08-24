# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: lti_users
#
#  id            :bigint           not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  lti_client_id :bigint           not null
#  lti_user_id   :string           not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_lti_users_on_lti_client_id_and_lti_user_id  (lti_client_id,lti_user_id) UNIQUE
#  index_lti_users_on_user_id_and_lti_client_id      (user_id,lti_client_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (lti_client_id => lti_clients.id)
#  fk_rails_...  (user_id => users.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class LtiUser < ApplicationRecord
  belongs_to :lti_client
  belongs_to :user
  validates :lti_user_id, presence: true, uniqueness: { scope: :lti_client_id }
end
