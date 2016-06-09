require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))
require 'shoulda'

class StudentMembershipTest < ActiveSupport::TestCase

  should belong_to :user
  should belong_to :grouping

  context 'A good Student Membership model' do
    setup do
      StudentMembership.make
    end

    should validate_presence_of :membership_status
  end

  should 'valide format of membership status' do
    # FIXME ? should probably be done using some magic should methods !
    membership = StudentMembership.new
    membership.grouping_id = 1
    membership.user_id = 1
    membership.membership_status = 'jdbffh'
    assert !membership.save, 'saved with a wrong format of membership_status'
  end

  should 'be able to spot an inviter' do
    membership = StudentMembership.make(
                  membership_status: StudentMembership::STATUSES[:inviter])
    assert membership.inviter?
  end

  should 'be able to spot an non inviter' do
    membership = StudentMembership.make(
                  membership_status: StudentMembership::STATUSES[:accepted])
    assert !membership.inviter?
  end
end
