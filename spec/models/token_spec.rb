require 'spec_helper'

describe Token do
  it { is_expected.to validate_presence_of(:remaining) }
  it { is_expected.to validate_presence_of(:grouping_id) }

  context 'token without remaining set to 5' do
    before {
      @grouping = create(:grouping)
      @token = Token.create(grouping_id: @grouping.id, last_used: nil, remaining: 5)
    }

    it 'be valid' do
      expect(@token).to be_valid
    end

    it 'be found' do
      expect(@token).to eq(Token.find_by_grouping_id(@token.grouping_id))
    end

    it 'not be found (wrong grouping_id)' do
      expect(Token.find_by_grouping_id(0)).to be_nil
    end
  end

  context 'token with remaining set to 0' do
    before {
      @grouping = create(:grouping)
      @token = Token.create(grouping_id: @grouping.id, last_used: nil, remaining: 0)
    }

    it 'be valid with remaining equal to 0' do
      expect(@token).to be_valid
    end
  end

  context 'methods' do
    describe '.decrease_tokens' do
      context 'when number of tokens is greater than 0' do
        before {
          @grouping = create(:grouping)
          @token = Token.create(grouping_id: @grouping.id, last_used: nil, remaining: 5)
          @token.decrease_tokens
        }

        it 'decrease number of tokens' do
          expect(@token.remaining).to eq (4)
        end

        it 'update the token used date' do
          expect(Time.now.strftime('%Y-%m-%d %H:%M')).to eq(@token.last_used.strftime('%Y-%m-%d %H:%M'))
        end
      end

      context 'when number of tokens is equal to 0' do
        before {
          @grouping = create(:grouping)
          @token = Token.create(grouping_id: @grouping.id, last_used: nil, remaining: 0)
        }

        it 'raise an error' do
          expect{@token.decrease_tokens}.to raise_error(RuntimeError)
        end
      end
    end

    describe '.reassign_tokens' do
      context 'if assignment.tokens is not nil' do
        before {
          @assignment = FactoryGirl.create(:assignment, token_start_date: 1.day.ago, tokens_per_period: 10)
          @group = FactoryGirl.create(:group)
          @grouping = Grouping.create(group: @group, assignment: @assignment)
          @token = Token.create(grouping_id: @grouping.id, remaining: '0', last_used: nil)
          @student_1 = FactoryGirl.create(:student)
          @student_2 = FactoryGirl.create(:student)
          StudentMembership.create(
            user: @student_1,
            grouping: @token.grouping,
            membership_status: StudentMembership::STATUSES[:inviter])
          StudentMembership.create(
            user: @student_2,
            grouping: @token.grouping,
            membership_status: StudentMembership::STATUSES[:accepted])
          @token.reassign_tokens
        }
        it 'reassign assignment tokens' do
          expect(@token.remaining).to eq(10)
        end
      end
    end

    describe '.update_tokens' do
      before {
        @grouping = create(:grouping)
        @token = Token.create(grouping_id: @grouping.id, last_used: nil, remaining: 5)
      }
      it 'update token count properly when it is being increased' do
        @token.update_tokens(6, 9)
        expect(@token.remaining).to eq(8)
      end

      it 'update token count properly when it is being decreased' do
        @token.update_tokens(6, 3)
        expect(@token.remaining).to eq(2)
      end

      it 'not allow token count to go below 0' do
        @token.update_tokens(6, 0)
        expect(@token.remaining).to eq(0)
      end
    end
  end
end
