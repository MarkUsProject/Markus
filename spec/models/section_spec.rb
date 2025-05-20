describe Section do
  let(:section) { create(:section) }

  context 'validations' do
    subject { build(:section) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:course_id) }
    it { is_expected.to have_many(:students) }
    it { is_expected.to have_many(:assessment_section_properties) }

    it { is_expected.not_to allow_value('A!a.sa').for(:name) }
    it { is_expected.not_to allow_value('<abc').for(:name) }

    it { is_expected.to allow_value('abc 234').for(:name) }
    it { is_expected.to allow_value('Ads_-hb').for(:name) }
    it { is_expected.to allow_value('-22125-k1lj42_').for(:name) }

    it { is_expected.to belong_to(:course) }

    it 'fails with error message when invalid name format' do
      subject.name = 'Invalid!@'
      error_key = 'activerecord.errors.models.section.attributes.name.invalid'
      expected_error = I18n.t(error_key, attribute: 'Name')

      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include(expected_error)
    end
  end

  describe '.has_students?' do
    context 'A section with students associated to' do
      it 'return true to has_students?' do
        section.students.create!(course: section.course, user_attributes: { user_name: 'exist_student',
                                                                            first_name: 'Nelle',
                                                                            last_name: 'Varoquaux',
                                                                            type: 'EndUser' })
        expect(section.has_students?).to be true
      end
    end

    context 'A section with no student associated to' do
      it 'return false to has_students?' do
        expect(section.has_students?).to be false
      end
    end
  end

  describe '.count_students' do
    context 'A section with students associated to' do
      it 'return 1 to students associated to' do
        section.students.create!(course: section.course, user_attributes: { user_name: 'exist_student',
                                                                            first_name: 'Shrek',
                                                                            last_name: 'Varoquaux',
                                                                            type: 'EndUser' })
        expect(section.count_students).to eq(1)
      end
    end

    context 'A section with no student associated to' do
      it 'return 0 to count_student' do
        expect(section.count_students).to eq(0)
      end
    end
  end

  describe '#starter_file_group_for' do
    let(:assignment) { create(:assignment) }
    let(:sections) { create_list(:section, 2) }
    let!(:starter_file_groups) { create_list(:starter_file_group_with_entries, 2, assignment: assignment) }

    before do
      create(:section_starter_file_group, starter_file_group: starter_file_groups.second, section: sections.second)
    end

    it 'should return the assignment default for a section without a section starter file group' do
      expect(sections.first.starter_file_group_for(assignment)).to eq starter_file_groups.first
    end

    it 'should return the assigned starter file group for a section with a section starter file group' do
      expect(sections.second.starter_file_group_for(assignment)).to eq starter_file_groups.second
    end
  end

  describe '#update_starter_file_group' do
    let(:assignment) { create(:assignment) }
    let(:sections) { create_list(:section, 2) }
    let!(:starter_file_groups) { create_list(:starter_file_group_with_entries, 2, assignment: assignment) }

    before do
      create(:section_starter_file_group, starter_file_group: starter_file_groups.second, section: sections.second)
    end

    context 'when a starter file group is not already assigned' do
      let(:section) { sections.first }

      before { section.update_starter_file_group(assignment.id, starter_file_groups.first.id) }

      it 'should assign the new starter file group' do
        ids = section.reload.section_starter_file_groups.pluck(:starter_file_group_id)
        expect(ids).to include starter_file_groups.first.id
      end
    end

    context 'when a starter file group is already assigned for that assignment' do
      let(:section) { sections.second }

      before { section.update_starter_file_group(assignment.id, starter_file_groups.first.id) }

      it 'should assign the new starter file group' do
        ids = section.reload.section_starter_file_groups.pluck(:starter_file_group_id)
        expect(ids).to include starter_file_groups.first.id
      end

      it 'should remove the old starter file group' do
        ids = section.reload.section_starter_file_groups.pluck(:starter_file_group_id)
        expect(ids).not_to include starter_file_groups.second.id
      end
    end

    context 'when a starter file group is assigned for a different assignment' do
      let(:assignment2) { create(:assignment) }
      let!(:starter_file_groups2) { create_list(:starter_file_group_with_entries, 2, assignment: assignment2) }
      let(:section) { sections.second }

      before do
        create(:section_starter_file_group, starter_file_group: starter_file_groups2.second, section: section)
        section.update_starter_file_group(assignment.id, starter_file_groups.first.id)
      end

      it 'should assign the new starter file group' do
        ids = section.reload.section_starter_file_groups.pluck(:starter_file_group_id)
        expect(ids).to include starter_file_groups.first.id
      end

      it 'should not remove the starter file group for the other assignment' do
        ids = section.reload.section_starter_file_groups.pluck(:starter_file_group_id)
        expect(ids).to include starter_file_groups2.second.id
      end
    end
  end
end
