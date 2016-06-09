require File.expand_path(File.join(File.dirname(__FILE__), '..', 'test_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'blueprints', 'helper'))

require 'shoulda'

class MembershipTest < ActiveSupport::TestCase

  should belong_to :user
  should belong_to :grouping
  should have_many :grace_period_deductions
  should validate_presence_of(:user_id).with_message('needs a user id')
  should validate_presence_of(:grouping_id).with_message('needs a grouping id')

  context 'StudentMembership is inviter' do
    setup do
      @membership = StudentMembership.make(membership_status: StudentMembership::STATUSES[:inviter])
    end

    should 'be inviter' do
      assert @membership.inviter?
    end

  end

  context 'StudentMembership is not inviter' do
    setup do
      @membership = StudentMembership.make(membership_status: StudentMembership::STATUSES[:accepted])
    end

    should 'not be inviter' do
      assert !@membership.inviter?
    end

  end
end
