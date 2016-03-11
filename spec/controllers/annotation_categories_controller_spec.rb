require 'spec_helper'

describe AnnotationCategoriesController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(build(:admin))
  end

  let(:annotation_category) { FactoryGirl.create(:annotation_category) }
  let(:assignment) { FactoryGirl.create(:assignment) }

  context 'csv_upload' do
    before :each do
      # We need to mock the rack file to return its content when
      # the '.read' method is called to simulate the behaviour of
      # the http uploaded file
      @file_good = fixture_file_upload(
        'files/annotation_categories/form_good.csv', 'text/csv')
      allow(@file_good).to receive(:read).and_return(
        File.read(fixture_file_upload(
                    'files/annotation_categories/form_good.csv',
                    'text/csv')))

      @file_invalid_column = fixture_file_upload(
        'files/annotation_categories/form_invalid_column.csv', 'text/csv')
      allow(@file_invalid_column).to receive(:read).and_return(
        File.read(fixture_file_upload(
                    'files/annotation_categories/form_invalid_column.csv',
                    'text/csv')))

      @file_bad_csv = fixture_file_upload(
        'files/bad_csv.csv', 'text/xls')
      allow(@file_bad_csv).to receive(:read).and_return(
        File.read(fixture_file_upload('files/bad_csv.csv', 'text/csv')))

      @file_wrong_format = fixture_file_upload(
        'files/wrong_csv_format.xls', 'text/xls')
      allow(@file_wrong_format).to receive(:read).and_return(
        File.read(fixture_file_upload(
                    'files/wrong_csv_format.xls', 'text/csv')))
      # This must line up with the second entry in the file_good
      @test_category_name = 'test_category'
      @test_content = 'c6conley'
    end

    it 'accepts a valid file' do
      post :csv_upload,
           assignment_id: assignment.id,
           annotation_category_list_csv: @file_good

      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(flash[:success]).to eq([I18n.t('csv_valid_lines',
                                           valid_line_count: 2)])
      expect(response).to redirect_to(action: 'index',
                                      id: assignment.id)

      expect(AnnotationCategory.all.size).to eq(2)
      # check that the data is being updated, in particular
      # the last element in the file.
      found_cat = false
      AnnotationCategory.all.each do |ac|
        next unless ac['annotation_category_name'] == @test_category_name
        found_cat = true
        expect(AnnotationText.where(annotation_category: ac).take['content'])
          .to eq(@test_content)
      end
      expect(found_cat).to eq(true)
    end

    it 'does not accept files with invalid columns' do
      post :csv_upload,
           assignment_id: assignment.id,
           annotation_category_list_csv: @file_invalid_column

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(action: 'index',
                                      id: assignment.id)
    end

    it 'does not accept fileless submission' do
      post :csv_upload,
           assignment_id: assignment.id

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(action: 'index',
                                      id: assignment.id)
    end

    it 'does not accept a non-csv file with .csv extension' do
      post :csv_upload,
           assignment_id: assignment.id,
           annotation_category_list_csv: @file_bad_csv

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(response).to redirect_to(action: 'index',
                                      id: assignment.id)
    end

    it 'does not accept a .xls file' do
      post :csv_upload,
           assignment_id: assignment.id,
           annotation_category_list_csv: @file_wrong_format

      expect(response.status).to eq(302)
      expect(flash[:error]).to_not be_empty
      expect(flash[:error])
        .to eq([t('csv.upload.non_text_file_with_csv_extension')])
      expect(response).to redirect_to(action: 'index',
                                      id: assignment.id)
    end
  end
end
