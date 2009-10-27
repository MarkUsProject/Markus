require File.dirname(__FILE__) + '/../test_helper'
require 'shoulda'

class StudentMembershipTest < ActiveSupport::TestCase
  should_belong_to :user
  should_belong_to :grouping

  def test_should_not_save_without_membership_status
    membership = StudentMembership.new
    membership.grouping_id = 1
    membership.user_id = 1
    assert !membership.save, "saved without a status"
  end

  def test_validates_format_of_membership_status
    membership = StudentMembership.new
    membership.grouping_id = 1
    membership.user_id = 1
    membership.membership_status = "jdbffh"
    assert !membership.save, "saved with a wrong format of
    membership_status"
  end

  def test_save_studentmembership
    membership = StudentMembership.new
    membership.grouping_id = 1
    membership.user_id = 1
    membership.membership_status = StudentMembership::STATUSES[:inviter]
    assert membership.save, "didn't save anything!!!"
  end

  def test_inviter_if_student_is_inviter
    membership = StudentMembership.new
    membership.grouping_id = 1
    membership.user_id = 1
    membership.membership_status = StudentMembership::STATUSES[:inviter]
    membership.save
    assert membership.inviter?, "returns false even if student is
    inviter"
  end

  def test_inviter_if_student_is_not_inviter
    membership = StudentMembership.new
    membership.grouping_id = 1
    membership.user_id = 1
    membership.membership_status = StudentMembership::STATUSES[:accepted]
    membership.save
    assert !membership.inviter?, "returns false even if student is
    inviter"
  end
end
