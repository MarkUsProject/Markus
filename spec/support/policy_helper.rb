module PolicyHelper
  def apply_policy(record, user, function)
    policy = described_class.new(record, user: user)
    policy.apply(function)
  end
end
