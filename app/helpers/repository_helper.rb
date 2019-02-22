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
end
