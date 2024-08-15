FactoryBot.define do
  factory :ta, class: 'Ta', parent: :role do
    transient do
      manage_assessments { false }
      run_tests { false }
      manage_submissions { false }
    end

    after(:create) do |ta, permission|
      if permission.manage_assessments
        ta.grader_permission.update(manage_assessments: true)
      end
      if permission.run_tests
        ta.grader_permission.update(run_tests: true)
      end
      if permission.manage_submissions
        ta.grader_permission.update(manage_submissions: true)
      end
    end
  end
end
