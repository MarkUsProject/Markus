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
end
