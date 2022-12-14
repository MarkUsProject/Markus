FactoryBot.define do
  factory :git_repository, class: GitRepository do
    initialize_with do
      course = Course.first || build(:course)
      repo_path = File.join Repository::ROOT_DIR, course.name, 'test_repo_workdir'
      GitRepository.create(repo_path, course) unless GitRepository.repository_exists?(repo_path)
      GitRepository.open(repo_path)
    end
  end
end
