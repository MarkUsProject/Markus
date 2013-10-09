namespace :markus do
  namespace :repos do
    desc "Destroy all repositories in REPOSITORY_STORAGE"
    task(:drop => :environment) do
      puts "Destroying Repositories..."
      FileUtils.rm_r Dir.glob(File.join(REPOSITORY_STORAGE, "*"))
      if File.exist?(REPOSITORY_PERMISSION_FILE)
        File.delete(REPOSITORY_PERMISSION_FILE)
      end
    end

    desc "Build repositories in REPOSITORY_STORAGE for all existing Groups"
    task(:build => :environment) do
      puts "Building Repositories for existing groups..."
      Group.all.each do |group|
        puts "Creating Repository for #{group.group_name}..."
        group.build_repository
      end
      puts "Creating Assignment folders..."
      Grouping.all.each do |grouping|
        grouping.create_grouping_repository_folder
      end
    end
  end
end
