class TimeIntervalType < ActiveRecord::Type::UnsignedInteger
  def deserialize(value)
    ActiveSupport::Duration.build(value)
  end
end
ActiveRecord::Type.register(:time_interval, TimeIntervalType)
