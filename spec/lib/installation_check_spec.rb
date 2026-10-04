describe InstallationCheck do
  subject(:result) { InstallationCheck.new(output: output).run }

  let(:output) { StringIO.new }

  it 'passes with the default test configuration' do
    expect(result).to be(true)
  end

  it 'reports each passing check' do
    result
    expect(output.string).to include('[PASS] logging.log_file:', '[PASS] logout_redirect: DEFAULT')
  end

  it 'resolves relative paths from the MarkUs root' do
    result
    log_dir = Rails.root.join(File.dirname(Settings.logging.log_file))
    expect(output.string).to include("[PASS] logging.log_file: #{log_dir}")
  end

  context 'when a directory is not writable' do
    before { allow(File).to receive(:writable?).and_return(false) }

    it 'fails and reports every failing check' do
      expect(result).to be(false)
      expect(output.string).to match(/\[FAIL\] logging\.log_file: .* is not writable/)
      expect(output.string).to match(/\[FAIL\] logging\.error_file: .* is not writable/)
    end
  end

  context 'when a file_storage directory does not exist yet' do
    before do
      allow(Settings).to receive(:file_storage).and_return(
        { 'default_root_path' => Rails.root.join('tmp/does/not/exist').to_s }
      )
    end

    it 'checks the closest existing ancestor directory' do
      expect(result).to be(true)
      expect(output.string).to include("[PASS] file_storage.default_root_path: #{Rails.root.join('tmp')}")
    end
  end

  context 'when a file_storage setting is nil' do
    before do
      allow(Settings).to receive(:file_storage).and_return(
        { 'default_root_path' => Rails.root.join('tmp').to_s, 'scanned_exams' => nil }
      )
    end

    it 'skips it' do
      expect(result).to be(true)
      expect(output.string).not_to include('file_storage.scanned_exams')
    end
  end

  context 'when logout_redirect is a URL' do
    before { allow(Settings).to receive(:logout_redirect).and_return('https://example.com') }

    it 'passes' do
      expect(result).to be(true)
    end
  end

  context 'when logout_redirect is invalid' do
    before { allow(Settings).to receive(:logout_redirect).and_return('example.com') }

    it 'fails' do
      expect(result).to be(false)
      expect(output.string).to include('[FAIL] logout_redirect: example.com is invalid')
    end
  end
end
