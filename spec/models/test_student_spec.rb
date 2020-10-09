describe TestStudent do
  context 'A Test Student model' do
    it 'will have many accepted groupings' do
      is_expected.to have_many(:accepted_groupings).through(:memberships)
    end

    it 'will have many student memberships' do
      is_expected.to have_many :student_memberships
    end
  end
end
