describe InstallationCheck do
  subject(:result) { InstallationCheck.new(output: output).run }

  let(:output) { StringIO.new }
  let(:scanned_exams_enabled) { false }
  let(:nbconvert_enabled) { false }
  let(:rmd_convert_enabled) { false }
  let(:installed_packages) { {} }
  # When set, commands that include this argument fail
  let(:failing_argument) { nil }

  let(:success_status) { instance_double(Process::Status, success?: true) }
  let(:failure_status) { instance_double(Process::Status, success?: false) }

  def pinned_version(requirements_file, package)
    Rails.root.join(requirements_file).read[/^#{package}==(\S+)/, 1]
  end

  before do
    allow(Settings.scanned_exams).to receive(:enabled).and_return(scanned_exams_enabled)
    allow(Rails.application.config).to receive_messages(nbconvert_enabled: nbconvert_enabled,
                                                        rmd_convert_enabled: rmd_convert_enabled)
    allow(Open3).to receive(:capture3) do |*args, **_kwargs|
      if failing_argument && args.include?(failing_argument)
        ['', "Error: #{failing_argument} failed\n", failure_status]
      elsif args.last.include?('importlib.metadata')
        [installed_packages.to_json, '', success_status]
      else
        ['', '', success_status]
      end
    end
  end

  it 'passes with the default test configuration' do
    expect(result).to be(true)
  end

  it 'skips the checks for disabled features without running any commands' do
    expect(Open3).not_to receive(:capture3)
    result
    expect(output.string).to include('[SKIP] scanned_exams.enabled: disabled',
                                     '[SKIP] nbconvert_enabled: disabled',
                                     '[SKIP] rmd_convert_enabled: disabled')
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

  context 'when a file_storage directory does not exist but its parent does' do
    before do
      allow(Settings).to receive(:file_storage).and_return(
        { 'default_root_path' => Rails.root.join('tmp/does-not-exist').to_s }
      )
    end

    it 'checks the parent directory' do
      expect(result).to be(true)
      expect(output.string).to include("[PASS] file_storage.default_root_path: #{Rails.root.join('tmp')}")
    end
  end

  context 'when neither a file_storage directory nor its parent exists' do
    let(:path) { Rails.root.join('tmp/does/not/exist') }

    before { allow(Settings).to receive(:file_storage).and_return({ 'default_root_path' => path.to_s }) }

    it 'fails' do
      expect(result).to be(false)
      expect(output.string).to include(
        "[FAIL] file_storage.default_root_path: neither #{path} nor its parent directory exists"
      )
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

  ['http://example.com', 'https://example.com/logout?a=b'].each do |url|
    context "when logout_redirect is #{url}" do
      before { allow(Settings).to receive(:logout_redirect).and_return(url) }

      it 'passes' do
        expect(result).to be(true)
      end
    end
  end

  ['example.com', 'ftp://example.com', 'http://', 'http:example.com', 'https://exa mple.com'].each do |url|
    context "when logout_redirect is #{url}" do
      before { allow(Settings).to receive(:logout_redirect).and_return(url) }

      it 'fails' do
        expect(result).to be(false)
        expect(output.string).to include("[FAIL] logout_redirect: #{url} is invalid")
      end
    end
  end

  context 'when scanned exams are enabled' do
    let(:scanned_exams_enabled) { true }
    let(:installed_packages) do
      { 'markus_exam_matcher' => pinned_version('requirements-scanner.txt', 'markus_exam_matcher') }
    end

    it 'passes when the dependencies are installed' do
      expect(result).to be(true)
      expect(output.string).to include(
        '[PASS] scanned_exams.enabled: Python packages in requirements-scanner.txt are installed',
        '[PASS] scanned_exams.enabled: markus_exam_matcher can be imported'
      )
    end

    context 'when the python executable cannot be run' do
      it 'fails and skips the remaining scanned exam checks' do
        expect(Open3).to receive(:capture3).once.and_raise(Errno::ENOENT)
        expect(result).to be(false)
        expect(output.string).to include('[FAIL] scanned_exams.enabled: Python executable can be run')
      end
    end

    context 'when a required package is not installed' do
      let(:installed_packages) { {} }

      it 'fails' do
        expect(result).to be(false)
        expect(output.string).to include('markus_exam_matcher is not installed')
      end
    end

    context 'when the wrong version of a required package is installed' do
      let(:installed_packages) { { 'Markus-Exam-Matcher' => '0.0.1' } }

      it 'fails' do
        expect(result).to be(false)
        expect(output.string).to match(/markus_exam_matcher 0\.0\.1 is installed but \S+ is required/)
      end
    end
  end

  context 'when nbconvert is enabled' do
    let(:nbconvert_enabled) { true }
    let(:installed_packages) do
      { 'nbconvert' => pinned_version('requirements-jupyter.txt', 'nbconvert'),
        'playwright' => pinned_version('requirements-jupyter.txt', 'playwright') }
    end

    it 'passes when the dependencies are installed' do
      expect(result).to be(true)
      expect(output.string).to include('[PASS] nbconvert_enabled: nbconvert can convert notebooks to HTML',
                                       '[PASS] nbconvert_enabled: nbconvert can convert notebooks to PDF')
    end

    context 'when notebooks cannot be converted to PDF' do
      let(:failing_argument) { 'webpdf' }

      it 'fails with a hint about installing Chromium' do
        expect(result).to be(false)
        expect(output.string).to include(
          '[FAIL] nbconvert_enabled: nbconvert can convert notebooks to PDF. Error: webpdf failed',
          'playwright install chromium'
        )
      end
    end
  end

  context 'when RMarkdown conversion is enabled' do
    let(:rmd_convert_enabled) { true }

    it 'passes when pandoc is installed' do
      expect(result).to be(true)
      expect(output.string).to include('[PASS] rmd_convert_enabled: pandoc is installed')
    end

    context 'when pandoc is not installed' do
      let(:failing_argument) { 'pandoc' }

      it 'fails' do
        expect(result).to be(false)
        expect(output.string).to include('[FAIL] rmd_convert_enabled: pandoc is installed')
      end
    end
  end
end
