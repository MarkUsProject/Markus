class Extension < ApplicationRecord
  belongs_to :grouping

  attribute :time_delta, :duration

  after_create :remove_pending_memberships

  PARTS = [:weeks, :days, :hours].freeze

  def self.to_parts(duration)
    parts = PARTS.zip([0] * PARTS.size).to_h
    if duration
      PARTS.each do |part|
        parts[part] = duration / 1.send(part)
        duration %= 1.send(part)
      end
    end
    parts
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
