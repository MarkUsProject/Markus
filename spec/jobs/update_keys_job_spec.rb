describe UpdateKeysJob do
  context 'when running as a background job' do
    let(:job_args) { [] }
    include_examples 'background job'
  end

  describe '#perform' do
    let(:file) { File.join(Rails.configuration.key_storage, KeyPair::AUTHORIZED_KEYS_FILE) }
    before :each do
      FileUtils.rm_rf(Rails.configuration.key_storage)
    end
    it 'should create a key storage directory if it does not exist' do
      UpdateKeysJob.perform_now
      expect(File.exist?(Rails.configuration.key_storage)).to be true
    end
    it 'should create an authorized_key file if it does not exist' do
      UpdateKeysJob.perform_now
      expect(File.exist?(file)).to be true
    end
    it 'should clear the old file content' do
      FileUtils.mkdir_p(Rails.configuration.key_storage)
      File.write(file, 'some text')
      UpdateKeysJob.perform_now
      expect(File.read(file)).to eq ''
    end
    context 'when there are some keys' do
      let!(:keys) { create_list :key_pair, 5 }
      it 'should write the keys to the file' do
        allow(KeyPair).to receive(:full_key_string).and_return('dummy line')
        UpdateKeysJob.perform_now
        expect(File.read(file).lines.length).to eq 5
      end
    end
  end
end
