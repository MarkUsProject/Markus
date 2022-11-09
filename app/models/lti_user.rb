class LtiUser < ApplicationRecord
  belongs_to :lti_client
  belongs_to :user
  validates :lti_user_id, uniqueness: { scope: :lti_client_id }
end
