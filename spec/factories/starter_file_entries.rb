FactoryBot.define do
  factory :starter_file_entry do
    association :starter_file_group
    path { Faker::Lorem.word + '.txt' }

    transient do
      is_file { true }
      content { 'some content' }
      extra_structure { {} }
    end

    before(:create) do |starter_file_entry, options|
      FileUtils.rm_rf starter_file_entry.full_path
      if options.is_file
        File.write(starter_file_entry.full_path, options.content)
      else
        FileUtils.mkdir_p(starter_file_entry.full_path)
        options.extra_structure.each do |path, content|
          full_path = starter_file_entry.full_path + path.to_s
          if content.nil?
            FileUtils.mkdir_p full_path
          else
            FileUtils.mkdir_p(full_path.dirname)
            File.write(full_path, content)
          end
        end
      end
    end
  end
end
