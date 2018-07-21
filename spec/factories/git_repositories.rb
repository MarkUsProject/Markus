FactoryBot.define do
  factory :git_repository, class: GitRepository do
    initialize_with do
      # Open the repo that was cloned in git_revision_spec.rb
      GitRepository.open("#{::Rails.root}/data/test/repos/test_repo_workdir")
    end
  end
end
