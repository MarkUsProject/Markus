# rubocop:disable Layout/LineLength, Lint/RedundantCopDisableDirective
# == Schema Information
#
# Table name: extensions
#
#  id            :bigint           not null, primary key
#  apply_penalty :boolean          default(FALSE), not null
#  note          :string
#  time_delta    :interval         not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grouping_id   :bigint           not null
#
# Indexes
#
#  index_extensions_on_grouping_id  (grouping_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (grouping_id => groupings.id)
#
# rubocop:enable Layout/LineLength, Lint/RedundantCopDisableDirective
class Extension < ApplicationRecord
  belongs_to :grouping

  has_one :course, through: :grouping

  attribute :time_delta, :interval

  validates :time_delta, numericality: { greater_than: 0 }

  after_create :validate_grouping

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

  def validate_grouping
    grouping.validate_grouping
  end
end
