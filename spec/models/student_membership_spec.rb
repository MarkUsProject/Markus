shared_examples 'vcs_submit=false' do |class_type|
  context 'when vcs_submit is false' do
    let!(:assignment) { create :assignment, vcs_submit: false }
    let!(:grouping) { create :grouping, assignment: assignment }
    let(:membership) { create class_type, grouping: grouping }
    it 'should not update permission file when created' do
      expect(Repository.get_class).not_to receive(:__update_permissions)
      membership
    end
    it 'should not update permission file when destroyed' do
      m = membership
      expect(Repository.get_class).not_to receive(:__update_permissions)
      m.destroy
    end
    it 'should not update permission file when updated' do
      if membership.inviter?
        membership.membership_status = 'pending'
      else
        membership.membership_status = 'inviter'
      end
      expect(Repository.get_class).not_to receive(:__update_permissions)
      membership.save!
    end
  end
end

def namer(bool)
  bool ? 'should update' : 'should not update'
end

shared_examples 'vcs_submit=true' do |class_type, update_hash|

  let!(:assignment) { create :assignment, vcs_submit: true }
  let!(:grouping) { create :grouping, assignment: assignment }
  let(:membership) { create class_type, grouping: grouping }

  context 'when vcs_submit is true' do
    it "#{namer update_hash[:create]} permission file when created" do
      if update_hash[:create]
        expect(Repository.get_class).to receive(:__update_permissions).once
      else
        expect(Repository.get_class).not_to receive(:__update_permissions)
      end
      membership
    end

    it "#{namer update_hash[:destroy]} permission file when destroyed" do
      m = membership
      if update_hash[:destroy]
        expect(Repository.get_class).to receive(:__update_permissions).once
      else
        expect(Repository.get_class).not_to receive(:__update_permissions)
      end
      m.destroy
    end

    status_hash = update_hash.select { |key| ![:create, :destroy].include?(key) }

    status_hash.each do |key, val|
      it "#{namer update_hash[key]} permission file when status is changed to #{key}" do
        m = membership
        if val
          expect(Repository.get_class).to receive(:__update_permissions).once
        else
          expect(Repository.get_class).not_to receive(:__update_permissions)
        end
        m.membership_status = key
        m.save!
      end
    end
  end
end

describe StudentMembership do
  context 'does validation' do
    it { is_expected.to validate_presence_of(:membership_status) }
    it { is_expected.to_not allow_value('blah').for :membership_status }
    it 'should belong to a student' do
      expect(create(:student_membership, user: create(:student))).to be_valid
    end
    it 'should not belong to an admin' do
      expect { create :student_membership, user: create(:admin) }.to raise_error(ActiveRecord::RecordInvalid)
    end
    it 'should not belong to an ta' do
      expect { create :student_membership, user: create(:ta) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'when is inviter' do
    let(:membership) { create :inviter_student_membership }
    it 'should be inviter' do
      expect(membership.inviter?).to be true
    end

    update_hash = { create: true, destroy: true, inviter: false, accepted: false, pending: true, rejected: true }
    include_examples 'vcs_submit=true', :inviter_student_membership, update_hash
    include_examples 'vcs_submit=false', :inviter_student_membership
  end

  context 'when is accepted' do
    let(:membership) { create :accepted_student_membership }

    it 'should not be inviter' do
      expect(membership.inviter?).to be false
    end

    update_hash = { create: true, destroy: true, inviter: false, accepted: false, pending: true, rejected: true }
    include_examples 'vcs_submit=true', :accepted_student_membership, update_hash
    include_examples 'vcs_submit=false', :accepted_student_membership
  end

  context 'when is pending' do
    let(:membership) { create :student_membership }

    it 'should not be inviter' do
      expect(membership.inviter?).to be false
    end

    update_hash = { create: false, destroy: false, inviter: true, accepted: true, pending: false, rejected: false }
    include_examples 'vcs_submit=true', :student_membership, update_hash
    include_examples 'vcs_submit=false', :student_membership
  end

  context 'when is rejected' do
    let(:membership) { create :rejected_student_membership }

    it 'should not be inviter' do
      expect(membership.inviter?).to be false
    end

    update_hash = { create: false, destroy: false, inviter: true, accepted: true, pending: false, rejected: false }
    include_examples 'vcs_submit=true', :rejected_student_membership, update_hash
    include_examples 'vcs_submit=false', :rejected_student_membership
  end
end
