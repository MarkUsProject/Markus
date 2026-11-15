describe Tag do
  subject { create(:tag, assessment: create(:assignment)) }

  let(:course) { create(:course) }
  let(:instructor) { create(:instructor, course: course) }
  let(:assignment) { create(:assignment, course: course) }
  let(:max_name) { 'a' * Tag::NAME_MAX_LENGTH }
  let(:too_long_name) { 'a' * (Tag::NAME_MAX_LENGTH + 1) }

  it { is_expected.to have_one(:course) }

  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:assessment_id) }

  it { is_expected.to validate_length_of(:name).is_at_most(Tag::NAME_MAX_LENGTH) }

  it_behaves_like 'course associations'

  describe '.from_csv' do
    let(:user_name) { instructor.user.user_name }

    it 'accepts a tag whose name is exactly the maximum length' do
      data = CSV.generate_line([max_name, 'description', user_name])

      result = nil
      expect { result = Tag.from_csv(data, course, assignment.id) }.to change { Tag.count }.by(1)
      expect(result[:invalid_lines]).to be_blank
    end

    it 'rejects tags with names longer than the maximum length' do
      data = CSV.generate_line([too_long_name, 'description', user_name])

      result = nil
      expect { result = Tag.from_csv(data, course, assignment.id) }.not_to(change { Tag.count })
      expect(result[:invalid_lines]).not_to be_empty
    end
  end

  describe '.from_yml' do
    let(:user_name) { instructor.user.user_name }

    def yml_row(name)
      { name: name, description: 'description', user: user_name }
    end

    it 'accepts a tag whose name is exactly the maximum length' do
      result = nil
      expect { result = Tag.from_yml([yml_row(max_name)], course, assignment.id) }
        .to change { Tag.count }.by(1)
      expect(result).not_to be_a(StandardError)
    end

    it 'rejects tags with names longer than the maximum length' do
      result = nil
      expect { result = Tag.from_yml([yml_row(too_long_name)], course, assignment.id) }
        .not_to(change { Tag.count })
      expect(result).to be_a(ArgumentError)
    end
  end
end
