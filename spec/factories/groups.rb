require 'faker'

FactoryBot.define do
  factory :group do
    course { Course.order(:id).first || association(:course) }
    sequence(:group_name) { |n| "group#{n}" }

    after(:create) do |group|
      if group.repo_name.nil?
        group.repo_name = "group_#{group.id.to_s.rjust(4, '0')}"
        group.save
      end
    end
  end

  factory :group_with_files_submitted, parent: :group do
    transient do
      submission_files { [] } # names of files to add
      assignment { association :assignment, strategy: :build }
    end

    after(:create) do |g, evaluator|
      Timecop.freeze(Time.current) do
        evaluator.submission_files.each do |filename|
          g.access_repo do |repo|
            txn = repo.get_transaction('test')
            path = File.join(evaluator.assignment.repository_folder, filename)
            txn.add(path, 'test', '')
            repo.commit(txn)
          end
        end
      end
    end
  end
end
