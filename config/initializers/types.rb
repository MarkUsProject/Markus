class DurationType < ActiveRecord::Type::String
  def cast(value)
    return value if value.blank? || value.is_a?(ActiveSupport::Duration)

    normalize_duration(ActiveSupport::Duration.parse(value))
  end

  def serialize(duration)
    duration ? remove_weeks(duration).iso8601 : nil
  end

  private

  # TODO: remove this after https://github.com/rails/rails/pull/34683 is pulled in
  def remove_weeks(duration)
    days_per_week = 7
    if duration.parts[:weeks] > 0
      duration - duration.parts[:weeks].weeks + (duration.parts[:weeks] * days_per_week).days
    else
      duration
    end
  end

  # TODO: remove this after https://github.com/rails/rails/pull/34683 is pulled in
  def normalize_duration(duration)
    ActiveSupport::Duration.build(duration)
  end
end

ActiveRecord::Type.register(:duration, DurationType)
