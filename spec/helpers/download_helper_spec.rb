describe DownloadHelper do
  include ActionController::DataStreaming

  describe 'send_file_download' do
    it 'should call send_file with the attachment disposition option' do
      expect_any_instance_of(ActionController::DataStreaming).to receive(:send_file) do |_, _, kwargs|
        expect(kwargs[:disposition]).to eq 'attachment'
      end
      send_file_download('tmp.txt')
    end

    it 'should override the disposition option' do
      expect_any_instance_of(ActionController::DataStreaming).to receive(:send_file) do |_, _, kwargs|
        expect(kwargs[:disposition]).to eq 'attachment'
      end
      send_file_download('tmp.txt', disposition: 'inline')
    end

    it 'should convert the mime type for javascript files to plaintext' do
      expect_any_instance_of(ActionController::DataStreaming).to receive(:send_file) do |_, _, kwargs|
        expect(kwargs[:type]).to eq 'text/plain'
      end
      send_file_download('tmp.js')
    end
  end

  describe 'send_data_download' do
    it 'should call send_data with the attachment disposition option' do
      expect_any_instance_of(ActionController::DataStreaming).to receive(:send_data) do |_, _, kwargs|
        expect(kwargs[:disposition]).to eq 'attachment'
      end
      send_data_download('')
    end

    it 'should override the disposition option' do
      expect_any_instance_of(ActionController::DataStreaming).to receive(:send_data) do |_, _, kwargs|
        expect(kwargs[:disposition]).to eq 'attachment'
      end
      send_data_download('', disposition: 'inline')
    end

    it 'should convert the mime type for javascript files to plaintext' do
      expect_any_instance_of(ActionController::DataStreaming).to receive(:send_data) do |_, _, kwargs|
        expect(kwargs[:type]).to eq 'text/plain'
      end
      send_data_download('', filename: 'text.js')
    end
  end
end
