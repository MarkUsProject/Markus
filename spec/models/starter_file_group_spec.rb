describe StarterFileGroup do
  describe 'validations' do
    subject { create :starter_file_group }

    it { is_expected.to belong_to(:assignment) }
    it { is_expected.to have_many(:section_starter_file_groups) }
    it { is_expected.to have_many(:sections) }
    it { is_expected.to have_many(:starter_file_entries) }
    it { is_expected.to validate_exclusion_of(:entry_rename).in_array(%w[.. .]) }
    it { is_expected.to have_one(:course) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:assessment_id) }
  end

  context 'more validations' do
    let(:starter_file_group) { create :starter_file_group }
    it 'should validate presence of entry rename if use_rename is true' do
      expect(build(:starter_file_group, entry_rename: nil, use_rename: true)).not_to be_valid
    end
    it 'should not validate presence of entry rename if use_rename is false' do
      expect(build(:starter_file_group, entry_rename: nil, use_rename: false)).to be_valid
    end
  end

  context 'callbacks' do
    it 'should remove files after it is destroyed' do
      grp = create(:starter_file_group)
      grp.destroy
      expect(grp.path).not_to exist
    end
    it 'should create a root directory after it is destroyed' do
      grp = create(:starter_file_group)
      expect(grp.path).to exist
    end
    it 'should sanitize the rename_entry' do
      expect(create(:starter_file_group, entry_rename: 'a/b').entry_rename).to eq 'b'
      expect(create(:starter_file_group, entry_rename: 'a:b').entry_rename).to eq 'a_b'
      expect(create(:starter_file_group, entry_rename: 'a&b').entry_rename).to eq 'a_b'
    end
    it 'should unset the default starter group if it is the default after it is destroyed' do
      assignment = create(:assignment)
      grp = create(:starter_file_group, assignment: assignment)
      assignment.update(default_starter_file_group_id: grp.id)
      grp.destroy
      expect(assignment.reload.default_starter_file_group_id).to be_nil
    end
    it 'should not unset the default starter group if it is not the default after it is destroyed' do
      assignment = create(:assignment)
      grp = create(:starter_file_group, assignment: assignment)
      grp2 = create(:starter_file_group)
      assignment.update(default_starter_file_group_id: grp2.id)
      grp.destroy
      expect(assignment.reload.default_starter_file_group_id).not_to be_nil
    end
    it 'should warn affected groupings after it is destroyed' do
      gsfe = create(:grouping_starter_file_entry)
      grouping = gsfe.grouping
      gsfe.starter_file_entry.starter_file_group.destroy
      expect(grouping.reload.starter_file_changed).to be true
    end
    it 'should update the starter file updated at value after a save' do
      assignment = create(:assignment)
      expect(assignment.starter_file_updated_at).to be_nil
      create(:starter_file_group, assignment: assignment)
      expect(assignment.starter_file_updated_at).to be_within(1.second).of(Time.current)
    end
    context 'setting the name when it is nil' do
      let(:assignment) { create :assignment }
      let(:assignment2) { create :assignment }
      let(:starter_file_group) { create :starter_file_group, assignment: assignment, name: nil }

      it 'returns the default name when there are no starter file groups' do
        expect(starter_file_group.name).to eq I18n.t('assignments.starter_file.new_starter_file_group')
      end

      it 'returns a fresh name when there are name collisions' do
        create(:starter_file_group,
               assignment: assignment,
               name: I18n.t('assignments.starter_file.new_starter_file_group'))
        create(:starter_file_group,
               assignment: assignment,
               name: "#{I18n.t('assignments.starter_file.new_starter_file_group')} (1)")
        create(:starter_file_group,
               assignment: assignment,
               name: "#{I18n.t('assignments.starter_file.new_starter_file_group')} (2)")

        expect(starter_file_group.name).to eq "#{I18n.t('assignments.starter_file.new_starter_file_group')} (3)"
      end

      it 'returns the default name when there are name collisions for a different assignment' do
        create(:starter_file_group,
               assignment: assignment2,
               name: I18n.t('assignments.starter_file.new_starter_file_group'))
        create(:starter_file_group,
               assignment: assignment2,
               name: "#{I18n.t('assignments.starter_file.new_starter_file_group')} (1)")
        create(:starter_file_group,
               assignment: assignment2,
               name: "#{I18n.t('assignments.starter_file.new_starter_file_group')} (2)")

        expect(starter_file_group.name).to eq I18n.t('assignments.starter_file.new_starter_file_group')
      end
    end
  end

  describe '#path' do
    let(:starter_file_group) { create :starter_file_group }
    it 'should return an absolute path to an entry on disk' do
      id_suffix = "#{starter_file_group.assignment.id}/#{starter_file_group.id}"
      expect(starter_file_group.path).to eq Pathname.new(StarterFileGroup.starter_files_dir) + id_suffix
      expect(starter_file_group.path).to exist
    end
  end

  describe '#files_and_dirs' do
    let(:starter_file_group) { create :starter_file_group_with_entries }
    it 'should contain the correct entries' do
      expect(starter_file_group.files_and_dirs).to contain_exactly('q1', 'q1/q1.txt', 'q2.txt')
    end
  end

  describe '#zip_starter_file_files' do
    let(:starter_file_group) { create :starter_file_group_with_entries }
    let(:user) { create :instructor }
    it 'should contain the correct entries' do
      zip_path = starter_file_group.zip_starter_file_files(user)
      Zip::File.open(zip_path) do |zip_file|
        expect(zip_file.find_entry('q1')).not_to be_nil
        expect(zip_file.find_entry('q2.txt')).not_to be_nil
        expect(zip_file.find_entry('q1/q1.txt')).not_to be_nil
      end
    end
  end

  describe '#update_entries' do
    let(:starter_file_group) { create :starter_file_group_with_entries }
    it 'should delete entries when a file is deleted' do
      FileUtils.rm_f starter_file_group.path + 'q2.txt'
      starter_file_group.update_entries
      expect(starter_file_group.reload.starter_file_entries.pluck(:path)).not_to include 'q2.txt'
    end
    it 'should not delete entries when a nested file is deleted' do
      FileUtils.rm_f starter_file_group.path + 'q1/q1.txt'
      starter_file_group.update_entries
      expect(starter_file_group.reload.starter_file_entries.pluck(:path)).to contain_exactly('q1', 'q2.txt')
    end
    it 'should delete entries when a folder is deleted' do
      FileUtils.rm_rf starter_file_group.path + 'q1'
      starter_file_group.update_entries
      expect(starter_file_group.reload.starter_file_entries.pluck(:path)).not_to include 'q1'
    end
    it 'should create entries when a file is created' do
      File.write(starter_file_group.path + 'new_file.txt', 'something')
      starter_file_group.update_entries
      expect(starter_file_group.reload.starter_file_entries.pluck(:path)).to include 'new_file.txt'
    end
    it 'should create entries when a folder is created' do
      FileUtils.mkdir_p(starter_file_group.path + 'new_folder')
      starter_file_group.update_entries
      expect(starter_file_group.reload.starter_file_entries.pluck(:path)).to include 'new_folder'
    end
    it 'should warn affected groupings' do
      gsfe = create(:grouping_starter_file_entry, starter_file_group: starter_file_group)
      grouping = gsfe.grouping
      starter_file_group.update_entries
      expect(grouping.reload.starter_file_changed).to be true
    end
    it 'should not warn non-affected groupings' do
      create(:grouping_starter_file_entry, starter_file_group: starter_file_group)
      grouping = create(:grouping)
      starter_file_group.update_entries
      expect(grouping.starter_file_changed).to be false
    end
  end

  describe '#should_rename' do
    it 'should return true if use_rename is true, there is something to rename it to, and the rule is shuffle' do
      [true, false].each do |use_rename|
        ['', nil, 'something'].each do |entry_rename|
          AssignmentProperties::STARTER_FILE_TYPES.each do |sftype|
            grp = build(:starter_file_group,
                        use_rename: use_rename,
                        entry_rename: entry_rename,
                        assignment: create(:assignment,
                                           assignment_properties_attributes: { starter_file_type: sftype }))
            expect(grp.should_rename).to eq(use_rename && entry_rename == 'something' && sftype == 'shuffle')
          end
        end
      end
    end
  end
end
