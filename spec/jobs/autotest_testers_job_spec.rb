describe AutotestTestersJob do
  let(:dummy_return) { OpenStruct.new(body: '{"a": 12}') }
  before do
    allow(File).to receive(:write)
    allow(File).to receive(:read).and_return("123456789\n")
  end
  context 'when running as a background job' do
    let(:job_args) { [] }
    include_examples 'background job'
  end
  describe '#perform' do
    subject { described_class.perform_now }
    it 'should set headers' do
      expect_any_instance_of(AutotestTestersJob).to receive(:send_request!) do |_job, net_obj|
        expect(net_obj['Api-Key']).to eq '123456789'
        expect(net_obj['Content-Type']).to eq 'application/json'
        dummy_return
      end
      subject
    end
    it 'should send an api request to the autotester' do
      expect_any_instance_of(AutotestTestersJob).to receive(:send_request!) do |_job, net_obj, uri|
        expect(net_obj.instance_of?(Net::HTTP::Get)).to be true
        expect(uri.to_s).to eq "#{Settings.autotest.url}/schema"
        dummy_return
      end
      subject
    end
    context 'the return value is valid json' do
      it 'should write the value to a file' do
        allow_any_instance_of(AutotestTestersJob).to receive(:send_request!).and_return(dummy_return)
        expect(File).to receive(:write).with(File.join(Settings.autotest.client_dir, 'testers.json'), '{"a":12}')
        subject
      end
    end
    context 'the return value is not valid json' do
      let(:dummy_return) { OpenStruct.new(body: 'something else') }
      it 'should raise an exception' do
        allow_any_instance_of(AutotestTestersJob).to receive(:send_request!).and_return(dummy_return)
        expect { subject }.to raise_error(JSON::ParserError)
      end
    end
  end
end
