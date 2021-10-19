require 'rails_helper'

describe Role do
  let!(:course) { create(:course) }

  it { is_expected.to allow_value('Student').for(:type) }
  it { is_expected.to allow_value('Admin').for(:type) }
  it { is_expected.to allow_value('Ta').for(:type) }
  it { is_expected.not_to allow_value('OtherTypeOfUser').for(:type) }

  context 'A good Role model' do
    it 'should be able to create a student' do
      create(:student, course_id: course.id)
    end
    it 'should be able to create an admin' do
      create(:admin, course_id: course.id)
    end
    it 'should be able to create a grader' do
      create(:ta, course_id: course.id)
    end
  end

  context 'The repository permissions file' do
    context 'should be upated' do
      it 'when creating an admin' do
        expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
        create(:admin)
      end
      it 'when destroying an admin' do
        admin = create(:admin)
        expect(UpdateRepoPermissionsJob).to receive(:perform_later).once
        admin.destroy
      end
    end
    context 'should not be updated' do
      it 'when creating a ta' do
        expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
        create(:ta)
      end
      it 'when destroying a ta without memberships' do
        ta = create(:ta)
        expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
        ta.destroy
      end
      it 'when creating a student' do
        expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
        create(:student)
      end
      it 'when destroying a student without memberships' do
        student = create(:student)
        expect(UpdateRepoPermissionsJob).not_to receive(:perform_later)
        student.destroy
      end
    end
  end
end
