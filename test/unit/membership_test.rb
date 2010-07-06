require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class MembershipTest < ActiveSupport::TestCase
  fixtures :all

  should belong_to :user
  should belong_to :grouping
  # should validate_presence_of :user_id
  # should validate_presence_of :grouping_id

################################################################################
#
# STUDENT_MEMBERSHIPS TESTS
#
################################################################################

  def test_if_studentmembership_is_inviter_true
    membership = memberships(:membership1)
    assert membership.inviter?
  end

  def test_if_studentmembership_is_inviter_false
    membership = memberships(:membership2)
    assert !membership.inviter?
  end

end
