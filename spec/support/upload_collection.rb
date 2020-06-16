shared_examples 'a controller supporting upload' do |formats: [:yml, :csv]|
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    # controller = described_class.new
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(FactoryBot.create(:admin))

    @initial_count = model_count
  end

  it 'does not accept request without an uploaded file' do
    post :upload, params: params

    expect(flash[:error]).not_to be_empty
    expect(model_count).to eq @initial_count
  end

  it 'does not accept an xls file' do
    post :upload, params: {
      **params,
      upload_file: fixture_file_upload('files/wrong_csv_format.xls')
    }
    expect(flash[:error]).to_not be_empty
    expect(model_count).to eq @initial_count
  end

  formats.each do |format|
    context "in #{format}" do
      it 'does not accept an empty file' do
        post :upload, params: {
          **params,
          upload_file: fixture_file_upload("files/upload_shared_files/empty.#{format}")
        }

        expect(flash[:error]).not_to be_empty
        expect(model_count).to eq @initial_count
      end

      it "does not accept an invalid file even with a .#{format} extension" do
        post :upload, params: {
          **params,
          upload_file: fixture_file_upload("files/upload_shared_files/bad_#{format}.#{format}")
        }

        expect(flash[:error]).to_not be_empty
        expect(model_count).to eq @initial_count
      end
    end
  end

  private

  def model_count
    if params[:model]
      params[:model].count
    else
      controller.controller_name.classify.constantize.count
    end
  end
end
