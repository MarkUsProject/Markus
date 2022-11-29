describe VersionReader do
  describe '.read_version' do
    let(:version_number) { "#{rand(0..100)}.#{rand(0..100)}.#{rand(0..100)}" }
    subject { VersionReader.read_version }
    it 'should allow a master version' do
      allow_any_instance_of(File).to receive(:read).and_return('VERSION=master')
      expect { subject }.not_to raise_error
    end
    it 'should not allow a generic release version' do
      allow_any_instance_of(File).to receive(:read).and_return('VERSION=release')
      expect { subject }.to raise_error(RuntimeError)
    end
    it 'should allow a properly formatted release version' do
      version = "VERSION=v#{version_number}"
      allow_any_instance_of(File).to receive(:read).and_return(version)
      expect { subject }.not_to raise_error
    end
    it 'should not allow a release version without a v prefix' do
      version = "VERSION=#{version_number}"
      allow_any_instance_of(File).to receive(:read).and_return(version)
      expect { subject }.to raise_error(RuntimeError)
    end
  end
end
