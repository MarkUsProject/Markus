# Generic helpers common to all specs.
module Helpers
  # Assigns all TAs in +tas+ to all +grouping+ without updating counts (e.g.,
  # the criteria coverage count) so that tests can verify the counts are
  # updated independently.
  def create_ta_memberships(groupings, tas)
    Array(groupings).each do |grouping|
      Array(tas).each do |ta|
        create(:ta_membership, grouping: grouping, user: ta)
      end
    end
  end

  # Reset the repos to empty
  def destroy_repos
    conf = Hash.new
    conf['IS_REPOSITORY_ADMIN'] = true
    conf['REPOSITORY_STORAGE'] =
        MarkusConfigurator.markus_config_repository_storage
    conf['REPOSITORY_PERMISSION_FILE'] = 'dummyfile'
    Repository.get_class(REPOSITORY_TYPE, conf).purge_all
  end
end
