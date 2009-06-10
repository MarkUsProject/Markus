require 'test_helper'

class MembershipTest < ActiveSupport::TestCase
  def test_should_not_save_without_user
    membership = Membership.new
    membership.grouping_id = 1
    assert !membership.save, "saved without a user"
  end

  def test_should_not_save_without_grouping
    membership = Membership.new
    membership.user_id = 1
    assert !membership.save, "saved without a user"
  end

end
