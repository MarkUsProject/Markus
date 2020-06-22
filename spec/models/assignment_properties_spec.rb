describe AssignmentProperties do
  describe 'ActiveModel validations' do
    it { is_expected.to validate_presence_of(:repository_folder) }
    it { is_expected.to validate_presence_of(:group_min) }
    it { is_expected.to validate_presence_of(:group_max) }

    it { is_expected.to validate_numericality_of(:group_min).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:group_max).is_greater_than(0) }

    it { should allow_value(true).for(:allow_web_submits) }
    it { should allow_value(false).for(:allow_web_submits) }
    it { should allow_value(true).for(:display_grader_names_to_students) }
    it { should allow_value(false).for(:display_grader_names_to_students) }

    it 'should not be valid with a negative duration' do
      extension = build(:timed_assignment, assignment_properties_attributes: { duration: -10.hours })
      expect(extension.valid?).to be(false)
    end
    it 'should be valid with a positive duration' do
      expect(build(:timed_assignment).valid?).to be(true)
    end
    it 'should not be valid with a nil duration' do
      extension = build(:timed_assignment, assignment_properties_attributes: { duration: nil })
      expect(extension.valid?).to be(false)
    end
    it 'should be valid with a bad duration if the assignment is not timed' do
      extension = build(:assignment, assignment_properties_attributes: { duration: -10.hours })
      expect(extension.valid?).to be(true)
    end
    it 'should check presence of start_time if this is a timed assignment' do
      extension = build(:timed_assignment, assignment_properties_attributes: { start_time: nil })
      expect(extension.valid?).to be(false)
    end
    it 'should not check presence of start_time if this is a timed assignment' do
      extension = build(:assignment, assignment_properties_attributes: { start_time: nil })
      expect(extension.valid?).to be(true)
    end
    it 'should check that the start_time is before the due_date if this is a timed assignment' do
      extension = build(:timed_assignment,
                        due_date: Time.now,
                        assignment_properties_attributes: { start_time: Time.now + 1.hour })
      expect(extension.valid?).to be(false)
    end
    it 'should not check that the start_time is before the due_date if this is a timed assignment' do
      extension = build(:assignment,
                        due_date: Time.now,
                        assignment_properties_attributes: { start_time: Time.now + 1.hour })
      expect(extension.valid?).to be(true)
    end
    it 'should not permit an assignment to be both scanned and timed' do
      extension = build(:timed_assignment, assignment_properties_attributes: { scanned_exam: true })
      expect(extension.valid?).to be(false)
    end
  end
  describe '#duration_parts' do
    let(:assignment) { create(:timed_assignment) }
    let(:parts) { assignment.duration_parts }
    it 'should return the duration attribute calculated as DURATION_PARTS' do
      duration_from_parts = AssignmentProperties::DURATION_PARTS.map { |part| parts[part].to_i.send(part) }.sum
      expect(assignment.duration).to eq(duration_from_parts)
    end
    it 'should return only the parts in DURATION_PARTS' do
      expect(parts.keys).to contain_exactly(*AssignmentProperties::DURATION_PARTS)
    end
  end
  describe 'self.duration_parts' do
    it 'should return the duration attribute calculated as DURATION_PARTS' do
      expect(AssignmentProperties.duration_parts(1.hour + 2.minutes)).to eq(hours: 1, minutes: 2)
    end
    it 'should return only the parts in DURATION_PARTS' do
      parts = AssignmentProperties.duration_parts(1.hour + 2.seconds)
      expect(parts.keys).to contain_exactly(*AssignmentProperties::DURATION_PARTS)
    end
  end
  describe '#adjusted_duration' do
    let(:assignment) { create(:timed_assignment) }
    context 'when there is enough time between the start time and the due date' do
      it 'should return the duration' do
        due_date = Time.now
        start_time = Time.now - assignment.duration - 10.minutes
        expect(assignment.adjusted_duration(due_date, start_time)).to eq(assignment.duration)
      end
      context 'when there is an added amount' do
        it 'should return the duration plus the added amount' do
          due_date = Time.now
          start_time = Time.now - assignment.duration - 10.minutes
          add = 5.minutes
          expect(assignment.adjusted_duration(due_date, start_time, add: add)).to eq(assignment.duration + add)
        end
      end
    end
    context 'when there is not enough time between the start time and the due date' do
      it 'should return the difference between the due date and start time' do
        due_date = Time.now
        start_time = Time.now - assignment.duration + 10.minutes
        expected = ActiveSupport::Duration.build((due_date - start_time).round)
        expect(assignment.adjusted_duration(due_date, start_time)).to eq(expected)
      end
      context 'when there is an added amount' do
        it 'should return the difference between the due date and start time' do
          due_date = Time.now
          start_time = Time.now - assignment.duration + 10.minutes
          add = 5.minutes
          expected = ActiveSupport::Duration.build((due_date - start_time).round)
          expect(assignment.adjusted_duration(due_date, start_time, add: add)).to eq(expected)
        end
      end
    end
  end
end
