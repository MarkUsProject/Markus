FactoryGirl.define do
  factory :git_repository, class: Repository::GitRepository do
    initialize_with do
      repository_config = Hash.new
      repository_config['REPOSITORY_STORAGE'] =
        "#{::Rails.root}/data/test/repos/test_repo"
      repository_config['REPOSITORY_PERMISSION_FILE'] =
        REPOSITORY_STORAGE + '/conf'
      repository_config['IS_REPOSITORY_ADMIN'] = true

      repo = Repository.get_class('git', repository_config)
      repo.create(repository_config['REPOSITORY_STORAGE'])
      repo.new(repository_config['REPOSITORY_STORAGE'])
    end
  end
end
