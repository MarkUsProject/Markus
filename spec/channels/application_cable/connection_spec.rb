require 'rails_helper'

describe ApplicationCable::Connection, type: :channel do
  context 'when attempting a connection' do
    let(:instructor) { create :instructor }
    context 'when user has signed in' do
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
    context 'when a user has switched roles' do
      let(:ta) { create :ta }
      it 'should establish the connection with current_user identifier set to the ta' do
        connect '/cable', session: { real_user_name: instructor.user_name, user_name: ta.user_name }
        expect(connection.current_user.user_name).to eq(ta.user_name)
      end
    end
  end
end
