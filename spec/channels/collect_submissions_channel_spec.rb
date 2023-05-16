require 'rails_helper'

describe CollectSubmissionsChannel, type: :channel do
  context 'when a user is logged in' do
    let!(:instructor) { create :instructor }
    before do
      stub_connection(current_user: instructor)
      subscribe
    end
    it 'should succeed' do
      # Asserts that the subscription was successfully created
      expect(subscription).to be_confirmed
    end
    it 'should stream from the correct user instance' do
      # Asserts that the channel subscribes connection to a stream created with `stream_for`
      expect(subscription).to have_stream_for(instructor)
    end
  end
end
