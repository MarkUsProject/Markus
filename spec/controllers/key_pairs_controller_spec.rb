describe KeyPairsController do
  render_views false
  let(:admin) { create :admin }

  before :each do
    allow(Rails.configuration.x.repository).to receive(:type).and_return('git')
  end

  describe 'GET index', :keep_memory_repos do
    before { get_as admin, :index }
    it 'should respond with success' do
      is_expected.to respond_with(:success)
    end
    it 'should render index' do
      expect(response).to render_template(:index)
    end
  end

  describe 'GET new', :keep_memory_repos do
    before { get_as admin, :new }
    it 'should respond with success' do
      is_expected.to respond_with(:success)
    end
    it 'should render new' do
      expect(response).to render_template(:new)
    end
  end

  describe 'POST create', :keep_memory_repos do
    shared_examples 'key_pair_create' do
      context 'a valid key' do
        let(:key) { 'ssh-rsa aaaaa' }
        let(:key_file) { 'files/key_pairs/id_rsa.good.pub' }
        it 'should respond with success' do
          is_expected.to respond_with(:redirect)
        end
        it 'should redirect' do
          expect(response).to redirect_to(action: :index)
        end
        it 'should flash a success message' do
          expect(flash[:success]).not_to be_empty
        end
      end
      context 'an invalid key' do
        let(:key) { 'aaaaa' }
        let(:key_file) { 'files/key_pairs/id_rsa.bad.pub' }
        it 'should render new' do
          expect(response).to render_template(:new)
        end
        it 'should flash an error message' do
          expect(flash[:error]).not_to be_empty
        end
      end
    end

    context 'uploading a string' do
      before { post_as admin, :create, params: { key_pair: { key_string: key } } }
      it_behaves_like 'key_pair_create'
    end
    context 'uploading a file' do
      before do
        post_as admin, :create, params: { key_pair: { file: fixture_file_upload(key_file) } }
      end
      it_behaves_like 'key_pair_create'
    end
  end

  describe 'DELETE destroy', :keep_memory_repos do
    before { delete_as admin, :destroy, params: { id: key_pair_id } }
    context 'a key_pair exists' do
      context 'owned by the current user' do
        let(:key_pair_id) { create(:key_pair, user: admin).id }
        it 'should delete the key_pair' do
          expect(KeyPair.where(id: key_pair_id)).to be_empty
        end
        it 'should respond with redirect' do
          is_expected.to respond_with(:redirect)
        end
        it 'should flash a success message' do
          expect(flash[:success]).not_to be_empty
        end
      end
      context 'not owned by the current user' do
        let(:key_pair_id) { create(:key_pair).id }
        it 'should not delete the key_pair' do
          expect(KeyPair.where(id: key_pair_id)).to exist
        end
        it 'should respond with redirect' do
          is_expected.to respond_with(:redirect)
        end
        it 'should not flash a success message' do
          expect(flash[:success]).to be_nil
        end
      end
    end
    context 'a key_pair does not exist' do
      let(:key_pair_id) { -1 }
      it 'should respond with redirect' do
        is_expected.to respond_with(:redirect)
      end
      it 'should not flash a success message' do
        expect(flash[:success]).to be_nil
      end
    end
  end
end
