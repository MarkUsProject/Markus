require 'spec_helper'

describe AssignmentFile do
  context 'a good AssignmentFile model' do
    it { is_expected.to belong_to(:assignment)}
    it { is_expected.to validate_presence_of(:filename )}
    it { is_expected.to validate_uniqueness_of(:filename).scoped_to(:assignment_id) }
    it { is_expected.to allow_value('est.java').for(:filename) }
    it { is_expected.not_to allow_value('est?java').for(:filename) }
    it { is_expected.not_to allow_value('&*%word^!').for(:filename) }
  end
end