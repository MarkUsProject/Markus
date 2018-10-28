describe Section do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to have_many(:students) }
  it { is_expected.to have_many(:section_due_dates) }

  describe '.has_students?' do
    context 'A section with students associated to' do
      it 'return true to has_students?' do
        section_1 = Section.create!(name: "Shrek")
        section_1.students.create!(user_name: 'exist_student', first_name: 'Nelle', last_name: 'Varoquaux')
        expect(section_1.has_students?).to be true
      end
    end

    context 'A section with no student associated to' do
      it 'return false to has_students?' do
        section_2 = Section.create!(name: "Shrek")
        expect(section_2.has_students?).to be false
      end
    end
  end

  describe '.count_students' do
    context 'A section with students associated to' do
      it 'return 1 to students associated to' do
        section_3 = Section.create!(name: "Shrek")
        section_3.students.create!(user_name: 'exist_student', first_name: 'Shrek', last_name: 'Varoquaux')
        expect(section_3.count_students).to eq(1)
      end
    end

    context 'A section with no student associated to' do
      it 'return 0 to count_student' do
        section_4 = Section.create!(name: "Shrek")
        expect(section_4.count_students).to eq(0)
      end
    end
  end

  describe '.section_due_date_for' do
    context 'A section with students associated to' do
      context 'With a section due date for an assignment' do
        it 'return the section due date for an assignment' do
          section_5 = Section.create!(name: "Shrek")
          assignment = create(:assignment,
                               section_due_dates_type: false,
                               due_date: 2.days.from_now)
          section_due_date = SectionDueDate.create!(section: section_5, assignment: assignment)

          expect(section_due_date).to eq(section_5.section_due_date_for(assignment))
        end
      end
    end
  end

end

