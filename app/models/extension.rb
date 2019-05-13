class Extension < ApplicationRecord
  belongs_to :grouping

  attribute :time_delta, :duration

  after_create :remove_pending_memberships

  private

  def remove_pending_memberships
    grouping.pending_student_memberships.destroy_all
    grouping.validate_grouping
  end
end
