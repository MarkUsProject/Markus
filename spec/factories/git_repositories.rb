FactoryGirl.define do
  factory :git_repository, class: Repository::GitRepository do
    initialize_with do
      repo = Repository.get_class('git')
      # Open the repo that was cloned from Gitolite in git_revision_spec.rb
      repo.open("#{::Rails.root}/data/test/repos/test_repo_workdir")
    end
  end
end
