FactoryBot.define do
  factory :starter_file_group do
    association :assignment
    name { Faker::Lorem.word }
    entry_rename { Faker::Lorem.word }
    use_rename { false }

    factory :starter_file_group_with_entries do
      transient do
        structure { { 'q1/': nil, 'q1/q1.txt': 'q1 content', 'q2.txt': 'q2 content' } }
      end

      after(:create) do |starter_file_group, options|
        FileUtils.rm_rf starter_file_group.path
        FileUtils.mkdir_p starter_file_group.path
        options.structure.each do |path, content|
          full_path = starter_file_group.path + path.to_s
          if content.nil?
            FileUtils.mkdir_p full_path
          else
            FileUtils.mkdir_p(full_path.dirname)
            File.write(full_path, content)
          end
        end
        starter_file_group.update_entries
      end
    end
  end
end
