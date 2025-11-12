shared_examples 'vcs_submit=false' do |class_type|
  context 'when vcs_submit is false' do
    let!(:assignment) { create(:assignment, assignment_properties_attributes: { vcs_submit: false }) }
    let!(:grouping) { create(:grouping, assignment: assignment) }
    let(:membership) { create(class_type, grouping: grouping) }

    it 'should not update permission file when created' do
      expect(Repository.get_class).not_to receive(:update_permissions_file)
      membership
    end

    it 'should not update permission file when destroyed' do
      m = membership
      expect(Repository.get_class).not_to receive(:update_permissions_file)
      m.destroy
    end

    it 'should not update permission file when updated' do
      if membership.inviter?
        membership.membership_status = 'pending'
      else
        membership.membership_status = 'inviter'
      end
      expect(Repository.get_class).not_to receive(:update_permissions_file)
      membership.save!
    end
  end
end

def namer(bool)
  bool ? 'should update' : 'should not update'
end

shared_examples 'vcs_submit=true' do |class_type, update_hash|
  let!(:assignment) { create(:assignment, assignment_properties_attributes: { vcs_submit: true }) }
  let!(:grouping) { create(:grouping, assignment: assignment) }
  let(:membership) { create(class_type, grouping: grouping) }

  context 'when vcs_submit is true' do
    it "#{namer update_hash[:create]} permission file when created" do
      if update_hash[:create]
        expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
      else
        expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
      end
      membership
    end

    it "#{namer update_hash[:destroy]} permission file when destroyed" do
      m = membership
      if update_hash[:destroy]
        expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
      else
        expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
      end
      m.destroy
    end

    status_hash = update_hash.reject { |key| [:create, :destroy].include?(key) }

    status_hash.each do |key, val|
      it "#{namer update_hash[key]} permission file when status is changed to #{key}" do
        m = membership
        if val
          expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
        else
          expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
        end
        m.membership_status = key
        m.save!
      end
    end
  end
end

describe StudentMembership do
  context 'does validation' do
    subject { create(:student_membership) }

    it { is_expected.to validate_presence_of(:membership_status) }
    it { is_expected.not_to allow_value('blah').for :membership_status }
    it { is_expected.to have_one(:course) }

    it_behaves_like 'course associations'
    it 'should belong to a student' do
      expect(create(:student_membership, role: create(:student))).to be_valid
    end

    it 'should not belong to an instructor' do
      expect { create(:student_membership, role: create(:instructor)) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'should not belong to an ta' do
      expect { create(:student_membership, role: create(:ta)) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    context 'validates if a student is accepted to multiple memberships for a single assignment' do
      let(:student) { create(:student) }
      let(:assignment) { create(:assignment) }
      let(:grouping) { create(:grouping, assignment: assignment) }
      let(:accepted_membership) { create(:accepted_student_membership, role: student, grouping: grouping) }
      let(:pending_membership) { create(:student_membership, role: student, grouping: grouping) }

      it 'should not allow if both are accepted' do
        create(:grouping_with_inviter, inviter: student, assignment: assignment)
        expect { accepted_membership }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'should not allow if there is already an accepted grouping' do
        create(:grouping_with_inviter, inviter: student, assignment: assignment)
        expect { pending_membership }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'should allow if there is already a pending grouping and the new one is accepted' do
        first_grouping = create(:grouping, assignment: assignment)
        create(:student_membership, role: student, grouping: first_grouping)
        expect { accepted_membership }.not_to raise_error
      end

      it 'should allow if both memberships are pending' do
        first_grouping = create(:grouping, assignment: assignment)
        create(:student_membership, role: student, grouping: first_grouping)
        expect { pending_membership }.not_to raise_error
      end

      it 'should allow you to modify an existing accepted grouping' do
        accepted_grouping = create(:grouping_with_inviter, inviter: student, assignment: assignment)
        membership = accepted_grouping.accepted_student_memberships.first
        expect { membership.update!(membership_status: StudentMembership::STATUSES[:pending]) }.not_to raise_error
      end

      it 'should allow you to modify an existing pending grouping' do
        membership = create(:student_membership, role: student, grouping: create(:grouping, assignment: assignment))
        expect { membership.update!(membership_status: StudentMembership::STATUSES[:accepted]) }.not_to raise_error
      end
    end
  end

  context 'when is inviter' do
    let(:membership) { create(:inviter_student_membership) }
    let(:update_hash) { { create: true, destroy: true, inviter: false, accepted: false, pending: true, rejected: true } }

    it 'should be inviter' do
      expect(membership.inviter?).to be true
    end

    it_behaves_like 'vcs_submit=true', :inviter_student_membership, { create: true, destroy: true, inviter: false, accepted: false, pending: true, rejected: true }
    it_behaves_like 'vcs_submit=false', :inviter_student_membership
  end

  context 'when is accepted' do
    let(:membership) { create(:accepted_student_membership) }
    let(:update_hash) { { create: true, destroy: true, inviter: false, accepted: false, pending: true, rejected: true } }

    it 'should not be inviter' do
      expect(membership.inviter?).to be false
    end

    it_behaves_like 'vcs_submit=true', :accepted_student_membership, { create: true, destroy: true, inviter: false, accepted: false, pending: true, rejected: true }
    it_behaves_like 'vcs_submit=false', :accepted_student_membership
  end

  context 'when is pending' do
    let(:membership) { create(:student_membership) }
    let(:update_hash) { { create: false, destroy: false, inviter: true, accepted: true, pending: false, rejected: false } }

    it 'should not be inviter' do
      expect(membership.inviter?).to be false
    end

    it_behaves_like 'vcs_submit=true', :student_membership, { create: false, destroy: false, inviter: true, accepted: true, pending: false, rejected: false }
    it_behaves_like 'vcs_submit=false', :student_membership
  end

  context 'when is rejected' do
    let(:membership) { create(:rejected_student_membership) }
    let(:update_hash) { { create: false, destroy: false, inviter: true, accepted: true, pending: false, rejected: false } }

    it 'should not be inviter' do
      expect(membership.inviter?).to be false
    end

    it_behaves_like 'vcs_submit=true', :rejected_student_membership, { create: false, destroy: false, inviter: true, accepted: true, pending: false, rejected: false }
    it_behaves_like 'vcs_submit=false', :rejected_student_membership
  end
end
