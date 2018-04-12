require 'repo/git_repository'

FactoryGirl.define do
  factory :git_repository, class: Repository::GitRepository do
    initialize_with do
      # Open the repo that was cloned in git_revision_spec.rb
      Repository::GitRepository.open("#{::Rails.root}/data/test/repos/test_repo_workdir")
    end
  end
end
