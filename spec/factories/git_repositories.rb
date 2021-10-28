FactoryBot.define do
  factory :git_repository, class: GitRepository do
    initialize_with do
      group = build(:group)
      group.repo_name = 'test_repo_workdir'
      repo_path = group.repo_path
      GitRepository.create(repo_path, group.course) unless GitRepository.repository_exists?(repo_path)
      GitRepository.open(repo_path)
    end
  end
end
