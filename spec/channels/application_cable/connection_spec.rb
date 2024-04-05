describe ApplicationCable::Connection do
  context 'when attempting a connection' do
    let(:instructor) { create(:instructor) }

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
      let(:ta) { create(:ta) }

      it 'should establish the connection with current_user identifier set to the ta' do
        connect '/cable', session: { real_user_name: instructor.user_name, user_name: ta.user_name }
        expect(connection.current_user.user_name).to eq(ta.user_name)
      end
    end
  end

  context 'when connecting with external auth' do
    context 'as an instructor' do
      let(:instructor) { create(:instructor) }

      it 'should connect' do
        connect '/cable', session: { auth_type: 'remote' }, headers: { HTTP_X_FORWARDED_USER: instructor.user_name }
        expect(connection.current_user.user_name).to eq(instructor.user_name)
      end

      context 'when role switched' do
        let(:ta) { create(:ta) }

        it 'should connect as the TA' do
          connect '/cable', session: { auth_type: 'remote', user_name: ta.user_name },
                            headers: { HTTP_X_FORWARDED_USER: instructor.user_name }
          expect(connection.current_user.user_name).to eq(ta.user_name)
        end
      end
    end

    context 'as a student' do
      let(:student) { create(:student) }
      let(:user_name) { student.user_name }

      it 'should connect' do
        connect '/cable', session: { auth_type: 'remote' }, headers: { HTTP_X_FORWARDED_USER: user_name }
        expect(connection.current_user.user_name).to eq(user_name)
      end
    end
  end
end
