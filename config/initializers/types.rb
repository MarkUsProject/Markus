class DurationType < ActiveRecord::Type::String
  def cast(value)
    return value if value.blank? || value.is_a?(ActiveSupport::Duration)

    ActiveSupport::Duration.parse(value)
  end

  def serialize(duration)
    duration ? duration.iso8601 : nil
  end
end

ActiveRecord::Type.register(:duration, DurationType)
