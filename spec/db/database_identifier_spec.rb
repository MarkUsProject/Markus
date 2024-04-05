describe 'Database Identifier Function' do
  let(:db_id) do
    ActiveRecord::Base.connection.execute('SELECT database_identifier()')[0]['database_identifier']
  end

  it 'should return a string that contains the current database' do
    expect(db_id).to include(ActiveRecord::Base.connection.current_database)
  end
end
