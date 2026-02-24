describe UploadHelper do
  describe '#parse_yaml_content' do
    it 'raises an error given a file with a cyclic alias' do
      contents = file_fixture('yml/cyclic.yml').read

      expect { parse_yaml_content(contents) }.to raise_error(StandardError, I18n.t('upload_errors.too_complex_yaml'))
    end

    it 'raises an error given a file with more expanded nodes than the configured limit' do
      contents = file_fixture('yml/billion-laughs.yml').read

      expect { parse_yaml_content(contents) }.to raise_error(StandardError, I18n.t('upload_errors.too_complex_yaml'))
    end

    it 'raises an error given a file with an alias that refers to a non-existent anchor' do
      contents = file_fixture('yml/non-existent-anchor.yml').read
      expect { parse_yaml_content(contents) }.to raise_error(StandardError, I18n.t('upload_errors.too_complex_yaml'))
    end

    it 'raises an error given a file with duplicate anchors' do
      contents = file_fixture('yml/duplicate-anchor.yml').read
      expect { parse_yaml_content(contents) }.to raise_error(StandardError, I18n.t('upload_errors.too_complex_yaml'))
    end
  end
end
