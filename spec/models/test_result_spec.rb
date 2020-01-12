describe TestResult do

  it { is_expected.to belong_to(:test_group_result) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:status) }
  it { is_expected.to validate_presence_of(:marks_earned) }
  it { is_expected.to validate_presence_of(:marks_total) }
  it { is_expected.to validate_inclusion_of(:status).in_array(%w[pass partial fail error]) }
  it { is_expected.to validate_numericality_of(:marks_earned) }
  it { is_expected.to validate_numericality_of(:marks_total) }
  it { is_expected.to validate_numericality_of(:time) }

  context 'test result' do
    before(:each) do
      @asst = create(:assignment)
      @grouping = create(:grouping, assignment: @asst)
      @sub = create(:submission, grouping: @grouping)
      @user = create(:admin)
      @test_group = TestGroup.create(
        assessment_id: @asst.id,
        name: 'test_group'
      )
      @test_run = TestRun.create(
        grouping: @grouping,
        submission: @sub,
        user: @user,
        revision_identifier: '1'
      )
      @test_group_result = TestGroupResult.create(
        test_group: @test_group,
        test_run: @test_run,
        marks_earned: 1,
        marks_total: 1,
        time: 0
      )
      @test_result = TestResult.create(
        test_group_result: @test_group_result,
        name: 'Unit test 1',
        status: 'pass',
        output: 'Output',
        marks_earned: 1,
        marks_total: 1
      )
    end

    context 'A valid test result' do

      it 'can be saved' do
        expect(@test_group_result).to be_valid
        expect(@test_group_result.save).to be true
      end

      it 'can have an empty output' do
        @test_result.output = ''
        expect(@test_result).to be_valid
        expect(@test_result.save).to be true
      end

      it 'can have zero marks earned' do
        @test_result.marks_earned = 0
        expect(@test_result).to be_valid
        expect(@test_result.save).to be true
      end

      it 'can have fractional marks earned' do
        @test_result.marks_earned = 0.5
        expect(@test_result).to be_valid
        expect(@test_result.save).to be true
      end

      it 'can have zero marks total' do
        @test_result.marks_total = 0
        expect(@test_result).to be_valid
        expect(@test_result.save).to be true
      end

      it 'can have fractional marks total' do
        @test_result.marks_total = 1.5
        expect(@test_result).to be_valid
        expect(@test_result.save).to be true
      end

      it 'can have zero marks total and zero marks earned' do
        @test_result.marks_earned = 0
        @test_result.marks_total = 0
        expect(@test_result).to be_valid
        expect(@test_result.save).to be true
      end

      it 'can have marks earned greater than marks total' do
        @test_result.marks_earned = 2
        expect(@test_result).to be_valid
        expect(@test_result.save).to be true
      end

      it 'can have nil time' do
        @test_result.time = nil
        expect(@test_result).to be_valid
        expect(@test_result.save).to be true
      end

      it 'can be deleted' do
        expect(@test_result).to be_valid
        expect{@test_result.destroy}.to change {TestResult.count}.by(-1)
      end
    end

    context 'An invalid test result' do

      it 'has a nil output' do
        @test_result.output = nil
        expect(@test_result).not_to be_valid
      end

      it 'has negative marks earned' do
        @test_result.marks_earned = -1
        expect(@test_result).not_to be_valid
      end

      it 'has nil marks earned' do
        @test_result.marks_earned = nil
        expect(@test_result).not_to be_valid
      end

      it 'has negative marks total' do
        @test_result.marks_total = -1
        expect(@test_result).not_to be_valid
      end

      it 'has nil marks total' do
        @test_result.marks_total = nil
        expect(@test_result).not_to be_valid
      end

      it 'has negative time' do
        @test_result.time = -1
        expect(@test_result).not_to be_valid
      end
    end
  end
end
