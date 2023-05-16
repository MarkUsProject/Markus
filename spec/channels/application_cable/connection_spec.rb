require 'rails_helper'

describe ApplicationCable::Connection, type: :channel do
  context 'when attempting a connection' do
    context 'when user has signed in' do
      let(:instructor) { create :instructor }
      it 'should properly establish the connection' do
        connect '/cable', session: { real_user_name: instructor.user_name }
        expect(connection.current_user.user_name).to eq(instructor.user_name)
      end
    end
    context 'when user is not signed in' do
      it 'should reject the connection' do
        expect { connect '/cable' }.to have_rejected_connection
      end
    end
  end
end
