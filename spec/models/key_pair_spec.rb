describe KeyPair do
  context 'validations' do
    it { is_expected.to belong_to :user }
    it { is_expected.to validate_presence_of :public_key }

    it 'should not validate a multiline key' do
      expect(build(:key_pair, public_key: "ssh-rsa\nabcd").validate).to be false
    end

    it 'should not validate an invalid key type' do
      expect(build(:key_pair, public_key: 'aaaaaa abcd').validate).to be false
    end

    it 'should not validate an empty key' do
      expect(build(:key_pair, public_key: 'ssh-rsa').validate).to be false
    end

    it 'should validate a valid key' do
      expect(build(:key_pair).validate).to be true
    end
  end

  context 'callbacks' do
    it 'should strip the public_key before validation' do
      key = '    ssh-rsa something   '
      key_pair = build(:key_pair, public_key: key)
      expect(key_pair.public_key).to eq key
      key_pair.validate
      expect(key_pair.public_key).to eq key.strip
    end
  end
end
