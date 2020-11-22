describe MarkingSchemePolicy do
  let(:context) { { user: user } }
  describe_rule :manage? do
    succeed 'user is admin' do
      let(:user) { create :admin }
    end
    failed 'user is ta' do
      let(:user) { create :ta }
    end
    failed 'user is student' do
      let(:user) { create :student }
    end
  end
end
