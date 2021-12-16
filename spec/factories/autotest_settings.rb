FactoryBot.define do
  factory :autotest_setting do
    url { 'http://www.example.com' }
    api_key { 'someapikeyhere' }
    schema { { definitions: { files_list: {}, test_data_categories: {} } }.to_json }
  end
end
