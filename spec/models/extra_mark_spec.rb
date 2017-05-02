require 'spec_helper'

describe ExtraMark do

  context 'checks relationships' do
    it { is_expected.to belong_to(:result) }
    it { is_expected.to validate_presence_of(:result_id) }
    it { is_expected.to validate_numericality_of(:result_id).with_message(
      'result_id must be an id that is an integer greater than 0') }

    it { is_expected.not_to allow_value(0).for(:result_id) }
    it { is_expected.to allow_value(1).for(:result_id) }
    it { is_expected.to allow_value(2).for(:result_id) }
    it { is_expected.to allow_value(100).for(:result_id) }
    it { is_expected.not_to allow_value(-1).for(:result_id) }
    it { is_expected.not_to allow_value(-100).for(:result_id) }

    it { is_expected.to validate_presence_of(:unit) }
  end
end
