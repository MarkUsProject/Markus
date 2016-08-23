# Returns information about the repository that is configured in the
# configuration file
module RepositoryHelper
  # Returns configuration properties for the current configured
  # repository
  def repository_config
    conf = {}
    conf['IS_REPOSITORY_ADMIN'] =
        MarkusConfigurator.markus_config_repository_admin?
    conf['REPOSITORY_PERMISSION_FILE'] =
        MarkusConfigurator.markus_config_repository_permission_file
    conf['REPOSITORY_STORAGE'] =
        MarkusConfigurator.markus_config_repository_storage
    conf
  end

  def repository_already_exists?(repository_name)
    repo_path = File.join(
        MarkusConfigurator.markus_config_repository_storage, repository_name)
    if Repository.get_class(MarkusConfigurator.markus_config_repository_type).repository_exists?(repo_path)
      errors.add(:repo_name, repo_path)
      true
    else
      false
    end
  end
end
