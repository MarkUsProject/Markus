# Let's populate students repository with nice data

groups = Group.all
assignment = Assignment.find_by_short_identifier("A1")

file_dir  = File.join(File.dirname(__FILE__), '/data')
groups.each do |group|
  Dir.foreach(file_dir) do |filename|
    unless File.directory?(File.join(file_dir, filename))
      file_contents = File.open(File.join(file_dir, filename))
      file_contents.rewind
      group.access_repo do |repo|
        txn = repo.get_transaction(group.grouping_for_assignment(
                                           assignment.id
                                            ).inviter.user_name)
        path = File.join(assignment.repository_folder,
                       filename)
        txn.add(path,
                file_contents.read,
                '')
        repo.commit(txn)
      end
    end
  end
end

