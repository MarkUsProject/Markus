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
    Repository.get_class.purge_all
  end

  # Strip all html content and normalize whitespace in a string.
  # This is useful when comparing flash message contentents to
  # internationalized strings
  def extract_text(string)
    Nokogiri::HTML(string).text.strip.gsub(/\s+/, ' ')
  end

  def submit_file_at_time(assignment, group, txnname, time, filename, text)
    pretend_now_is(Time.parse(time)) do
      group.access_repo do |repo|
        txn = repo.get_transaction(txnname)
        txn = add_file_helper(assignment, txn, filename, text)
        repo.commit(txn)
      end
    end
  end

  def add_file_helper(assignment, txn, file_name, file_contents)
    path = File.join(assignment.repository_folder, file_name)
    txn.add(path, file_contents, '')
    txn
  end

  def submit_file(assignment, grouping, filename = 'file', content = 'content')
    grouping.group.access_repo do |repo|
      txn = repo.get_transaction('test')
      path = File.join(assignment.repository_folder, filename)
      txn.add(path, content, '')
      repo.commit(txn)

      # Generate submission
      Submission.generate_new_submission(grouping, repo.get_latest_revision)
    end
  end
end
