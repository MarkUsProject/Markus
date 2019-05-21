# ActiveRecord type that records a time duration. It should store a string
# type to the database that is a valid iso8601 string.
class DurationType < ActiveRecord::Type::String
  def cast(value)
    return value if value.blank? || value.is_a?(ActiveSupport::Duration)

    normalize_duration(ActiveSupport::Duration.parse(value))
  end

  def serialize(duration)
    duration ? remove_weeks(duration).iso8601 : nil
  end

  private

  # Convert weeks into days for a Duration object since iso8601 strings do not allow
  # weeks and days to be specified together.
  # TODO: remove this after https://github.com/rails/rails/pull/34683 is pulled in
  def remove_weeks(duration)
    days_per_week = 7
    if duration.parts[:weeks] > 0
      duration - duration.parts[:weeks].weeks + (duration.parts[:weeks] * days_per_week).days
    else
      duration
    end
  end

  # Convert a Duration object into another Duration object with the same total duration
  # but with parts with the smallest total values possible.
  #
  # For example: converts a duration with parts: {days: 10} to one with parts: {weeks: 1, days: 3}
  # TODO: remove this after https://github.com/rails/rails/pull/34683 is pulled in
  def normalize_duration(duration)
    ActiveSupport::Duration.build(duration)
  end
end

ActiveRecord::Type.register(:duration, DurationType)
