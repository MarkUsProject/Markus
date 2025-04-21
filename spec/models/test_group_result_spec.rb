describe TestGroupResult do
  subject { create(:test_group_result) }

  it { is_expected.to have_many(:test_results) }
  it { is_expected.to belong_to(:test_group) }
  it { is_expected.to belong_to(:test_run) }
  it { is_expected.to validate_presence_of(:marks_earned) }
  it { is_expected.to validate_presence_of(:marks_total) }
  it { is_expected.to validate_presence_of(:time) }
  it { is_expected.to validate_numericality_of(:marks_earned) }
  it { is_expected.to validate_numericality_of(:marks_total) }
  it { is_expected.to validate_numericality_of(:time) }
  it { is_expected.to have_one(:course) }

  it_behaves_like 'course associations'

  context 'test group result' do
    before do
      @asst = create(:assignment)
      @grouping = create(:grouping, assignment: @asst)
      @sub = create(:submission, grouping: @grouping)
      @role = create(:instructor)
      @test_group = create(:test_group, assignment: @asst)
      @test_run = create(:test_run, grouping: @grouping, submission: @sub, role: @role)
      @test_group_result = create(:test_group_result, test_group: @test_group, test_run: @test_run)
    end

    context 'A valid test group' do
      it 'can be saved' do
        expect(@test_group_result).to be_valid
        expect(@test_group_result.save).to be true
      end

      it 'can have zero marks earned' do
        @test_group_result.marks_earned = 0
        expect(@test_group_result).to be_valid
        expect(@test_group_result.save).to be true
      end

      it 'can have fractional marks earned' do
        @test_group_result.marks_earned = 0.5
        expect(@test_group_result).to be_valid
        expect(@test_group_result.save).to be true
      end

      it 'can have zero marks total' do
        @test_group_result.marks_total = 0
        expect(@test_group_result).to be_valid
        expect(@test_group_result.save).to be true
      end

      it 'can have fractional marks total' do
        @test_group_result.marks_total = 1.5
        expect(@test_group_result).to be_valid
        expect(@test_group_result.save).to be true
      end

      it 'can have zero marks total and zero marks earned' do
        @test_group_result.marks_earned = 0
        @test_group_result.marks_total = 0
        expect(@test_group_result).to be_valid
        expect(@test_group_result.save).to be true
      end

      it 'can have marks earned greater than marks total' do
        @test_group_result.marks_earned = 2
        expect(@test_group_result).to be_valid
        expect(@test_group_result.save).to be true
      end

      it 'can be deleted' do
        expect(@test_group_result).to be_valid
        expect { @test_group_result.destroy }.to change { TestGroupResult.count }.by(-1)
      end
    end

    context 'An invalid test group result' do
      it 'has negative marks earned' do
        @test_group_result.marks_earned = -1
        expect(@test_group_result).not_to be_valid
      end

      it 'has negative marks total' do
        @test_group_result.marks_total = -1
        expect(@test_group_result).not_to be_valid
      end

      it 'has negative time' do
        @test_group_result.time = -1
        expect(@test_group_result).not_to be_valid
      end

      it 'has fractional time' do
        @test_group_result.time = 0.5
        expect(@test_group_result).not_to be_valid
      end
    end
  end
end
