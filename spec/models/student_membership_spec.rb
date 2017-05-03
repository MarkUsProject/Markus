require 'spec_helper'

describe StudentMembership do

  context 'checks relationships' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:grouping) }
    it { is_expected.to validate_presence_of(:membership_status) }

    context 'A good Student Membership model' do
      before { StudentMembership.create }

      it { is_expected.to validate_presence_of(:membership_status) }
    end

    it 'valid format of membership status' do
      membership = StudentMembership.create(grouping_id: 1, user_id: 1, membership_status: 'blah')
      expect(membership.valid?).to be false
    end

    it 'be able to spot an inviter' do
      membership = StudentMembership.create(
        membership_status: StudentMembership::STATUSES[:inviter])
      expect(membership.inviter?).to be true
    end

    it 'be able to spot an non-inviter' do
      membership = StudentMembership.create(
        membership_status: StudentMembership::STATUSES[:accepted])
      expect(membership.inviter?).to be false
    end

  end
end
