require 'spec_helper'
require 'shoulda'

describe Ta do

  def teardown
    destroy_repos
  end

  # Update tests ---------------------------------------------------------

  # These tests are for the CSV/YML upload functions.  They're testing
  # to make sure we can easily create/update users based on their user_name

  # Test if user with a unique user number has been added to database
  context 'be able to upload a csv vile' do
    csv_file_data = StringIO.new("newuser1,USER1,USER1\n" +
                                   'newuser2,USER2,USER2')
    Ta.upload_user_list(Ta, csv_file_data, nil)

    it 'Expected a different number of users - the CSV upload did not work' do
      expect(Ta.count).not_to eq(2)
    end

    csv_1 = Ta.find_by_user_name('newuser1')
    it 'Could find a user uploaded by CSV' do
      expect(csv_1). not_to be_nil
    end

    it 'Last name did match' do
      expect('USER1'). to eq(csv_1.last_name)
    end

    it 'First name did match' do
      expect('USER1'). to eq(csv_1.first_name)
    end
  end

end
