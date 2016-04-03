require 'spec_helper'

describe TagsController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))
  end

  let(:assignment) { FactoryGirl.create(:assignment) }

  context 'download_tag_list' do
    let(:csv_options) do
      {
        type: 'text/csv',
        disposition: 'attachment',
        filename: 'tag_list.csv'
      }
    end

    before :each do
      @user = create(:student)
      @tag1 = Tag.find_or_create_by(name: 'tag1')
      @tag1.name = 'tag1'
      @tag1.description = 'tag1_description'
      @tag1.user = @user
      @tag1.save

      @tag2 = Tag.find_or_create_by(name: 'tag2')
      @tag2.name = 'tag2'
      @tag2.description = 'tag2_description'
      @tag2.user = @user
      @tag2.save
    end

    it 'responds with appropriate status' do
      get :download_tag_list,
          assignment_id: assignment.id,
          format: 'csv'
      expect(response.status).to eq(200)
    end

    # parse header object to check for the right disposition
    it 'sets disposition as attachment' do
      get :download_tag_list,
          assignment_id: assignment.id,
          format: 'csv'
      d = response.header['Content-Disposition'].split.first
      expect(d).to eq 'attachment;'
    end

    it 'expects a call to send_data' do
      csv_data =
        "#{@tag1.name},#{@tag1.description},#{@user.first_name} #{@user.last_name}\n" +
        "#{@tag2.name},#{@tag2.description},#{@user.first_name} #{@user.last_name}\n"
      expect(@controller).to receive(:send_data).with(csv_data, csv_options) {
        # to prevent a 'missing template' error
        @controller.render nothing: true
      }
      get :download_tag_list,
          assignment_id: assignment.id,
          format: 'csv'
    end

    # parse header object to check for the right content type
    it 'returns text/csv type' do
      get :download_tag_list,
          assignment_id: assignment.id,
          format: 'csv'
      expect(response.content_type).to eq 'text/csv'
    end
  end
end