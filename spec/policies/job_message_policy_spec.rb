describe JobMessagePolicy do
  let(:context) { { user: create(:admin) } }
  describe_rule :manage? do
    succeed
  end
end
