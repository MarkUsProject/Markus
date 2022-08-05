class Extension < ApplicationRecord
  belongs_to :grouping

  has_one :course, through: :grouping

  attribute :time_delta, :interval

  validates :time_delta, numericality: { greater_than: 0 }

  after_create :remove_pending_memberships

  PARTS = [:weeks, :days, :hours, :minutes].freeze

  def self.to_parts(duration)
    duration = duration.to_i
    PARTS.map do |part|
      amt = (duration / 1.public_send(part)).to_i
      duration -= amt.public_send(part)
      [part, amt]
    end.to_h
  end

  def to_parts
    Extension.to_parts(time_delta)
  end

  private

  def remove_pending_memberships
    grouping.pending_student_memberships.destroy_all
    grouping.validate_grouping
  end
end
