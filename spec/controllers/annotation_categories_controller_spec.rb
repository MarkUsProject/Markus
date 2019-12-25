describe AnnotationCategoriesController do
  before :each do
    # Authenticate user is not timed out, and has administrator rights.
    allow(controller).to receive(:session_expired?).and_return(false)
    allow(controller).to receive(:logged_in?).and_return(true)
    allow(controller).to receive(:current_user).and_return(FactoryBot.create(:admin))
  end

  let(:annotation_category) { FactoryBot.create(:annotation_category) }
  let(:assignment) { FactoryBot.create(:assignment) }

  context '#upload' do
    include_examples 'a controller supporting upload' do
      let(:params) { { assignment_id: assignment.id } }
    end

    it 'accepts a valid csv file' do
      file_good = fixture_file_upload('files/annotation_categories/form_good.csv', 'text/csv')

      post :upload, params: { assignment_id: assignment.id, upload_file: file_good }

      expect(response.status).to eq(302)
      expect(flash[:error]).to be_nil
      expect(flash[:success].map { |f| extract_text f }).to eq([I18n.t('upload_success',
                                                                       count: 2)].map { |f| extract_text f })
      expect(response).to redirect_to(action: 'index', assignment_id: assignment.id)

      expect(AnnotationCategory.all.size).to eq(2)
      # check that the data is being updated, in particular
      # the last element in the file.
      test_category_name = 'test_category'
      test_content = 'c6conley'
      found_cat = false
      AnnotationCategory.all.each do |ac|
        next unless ac['annotation_category_name'] == test_category_name

        found_cat = true
        expect(AnnotationText.where(annotation_category: ac).take['content']).to eq(test_content)
      end
      expect(found_cat).to eq(true)
    end

    # this test case is to test a file with an annotation under an annotation category that has no name
    it 'does not accept files with invalid columns' do
      @file_invalid_column = fixture_file_upload(
        'files/annotation_categories/form_invalid_column.csv', 'text/csv'
      )

      post :upload, params: { assignment_id: assignment.id, upload_file: @file_invalid_column }

      expect(response.status).to eq(302)
      # One annotation category was created, and one has an error.
      expect(AnnotationCategory.all.size).to eq(1)
      expect(flash[:error].size).to eq(1)
      expect(response).to redirect_to(action: 'index', assignment_id: assignment.id)
    end

    it 'accepts a valid yml file' do
      @valid_yml_file = fixture_file_upload('files/annotation_categories/valid_yml.yml', 'text/yml')
      post :upload, params: { assignment_id: assignment.id, upload_file: @valid_yml_file }

      expect(flash[:success].size).to eq(1)
      expect(response.status).to eq(302)

      annotation_category_list = AnnotationCategory.order(:annotation_category_name)
      index = 0
      while index < annotation_category_list.size
        curr_cat = annotation_category_list[index]
        expect(curr_cat.annotation_category_name).to be_eql(('Problem ' + (index + 1).to_s))
        expect(curr_cat.annotation_texts_count).to eq(1)
        expect(curr_cat.annotation_texts.all[0].content).to be_eql(('Test on question ' + (index + 1).to_s))
        index += 1
      end
      expect(annotation_category_list.size).to eq(4)
    end

    it 'does not accept files with empty annotation category name' do
      @yml_with_invalid_category = fixture_file_upload('files/annotation_categories/yml_with_invalid_category.yml')

      post :upload, params: { assignment_id: assignment.id,
                              upload_file: @yml_with_invalid_category }
      expect(response.status).to eq(302)
      expect(flash[:error].size).to eq(1)
      expect(AnnotationCategory.all.size).to eq(0)
      expect(response).to redirect_to action: 'index', assignment_id: assignment.id
    end
  end

  context 'CSV_Downloads' do
    let(:annotation_category) do
      create(:annotation_category,
             assignment: assignment)
    end
    let(:annotation_text) do
      create(:annotation_text,
             annotation_category: annotation_category)
    end
    let(:csv_data) do
      "#{annotation_category.annotation_category_name}," \
      "#{annotation_text.content}\n"
    end
    let(:csv_options) do
      {
        filename: "#{assignment.short_identifier}_annotations.csv",
        disposition: 'attachment'
      }
    end

    it 'responds with appropriate status' do
      get :download, params: { assignment_id: assignment.id }, format: 'csv'
      expect(response.status).to eq(200)
    end

    # parse header object to check for the right disposition
    it 'sets disposition as attachment' do
      get :download, params: { assignment_id: assignment.id }, format: 'csv'
      d = response.header['Content-Disposition'].split.first
      expect(d).to eq 'attachment;'
    end

    it 'expects a call to send_data' do
      expect(@controller).to receive(:send_data).with(csv_data, csv_options) {
        # to prevent a 'missing template' error
        @controller.head :ok
      }
      get :download, params: { assignment_id: assignment.id }, format: 'csv'
    end

    # parse header object to check for the right content type
    it 'returns text/csv type' do
      get :download, params: { assignment_id: assignment.id }, format: 'csv'
      expect(response.media_type).to eq 'text/csv'
    end

    # parse header object to check for the right file naming convention
    it 'filename passes naming conventions' do
      get :download, params: { assignment_id: assignment.id }, format: 'csv'
      filename = response.header['Content-Disposition']
                         .split[1].split('"').second
      expect(filename).to eq "#{assignment.short_identifier}_annotations.csv"
    end
  end

  context 'When searching for an annotation text' do
    before(:each) do
      @annotation_text_one = create(:annotation_text,
                                    annotation_category: annotation_category,
                                    content: 'This is an annotation text.')
    end

    it 'should render an annotation context, where first part of its content matches given string' do
      string = 'This is an'

      get :find_annotation_text, params: { assignment_id: annotation_category.assignment_id, string: string }
      expect(response.body).to eq(@annotation_text_one.content)
    end

    it 'should render an empty string if string does not match first part of any annotation text' do
      string = 'Hello'

      get :find_annotation_text, params: { assignment_id: assignment.id, string: string }
      expect(response.body).to eq('')
    end

    it 'should render an empty string if string matches first part of more than one annotation text' do
      annotation_text_two = create(:annotation_text,
                                   annotation_category: annotation_category,
                                   content: 'This is another annotation text.')
      string = 'This is an'

      get :find_annotation_text, params: { assignment_id: assignment.id, string: string }
      expect(response.body).to eq('')
    end
  end
end
