shared_examples 'run testers job' do
  subject { described_class.perform_now }
  let(:tmp_dir) { Dir.mktmpdir }
  before :each do
    allow(Rails.configuration.x.autotest).to receive(:client_dir).and_return(tmp_dir)
  end
  after :each do
    FileUtils.rm_rf tmp_dir
  end
  context 'when the job is performed without errors' do
    let(:data) { '{"good": [1, 2, 3]}' }
    let(:exit_code) { 0 }
    it 'should not raise an error' do
      subject
    end
    it 'should write the output to the testers.json file' do
      subject
      expect(File.read(File.join(tmp_dir, 'testers.json'))).to eq data
    end
  end
  context 'when the job is performed with errors' do
    let(:data) { 'some problem happened' }
    let(:exit_code) { 1 }
    it 'should raise an error with the process output' do
      expect { subject }.to raise_error(RuntimeError, data)
    end
    it 'should not write to the testers.json file' do
      expect { subject }.to raise_error(RuntimeError)
      expect(File.exist?(File.join(tmp_dir, 'testers.json'))).to be false
    end
  end
end

describe AutotestTestersJob do
  context 'when running as a background job' do
    let(:job_args) { [] }
    include_examples 'background job'
  end
  it_behaves_like 'shared autotest job tests', 'run testers job'
end
