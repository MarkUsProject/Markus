module Util
  # Take an Enumerable of +hashes+ and group them by the given +group_by_keys+,
  # returning a list of hashes where each returned hash contains the keys
  # and corresponding values of a group, and an additional key +group_result_key+
  # that corresponds to a list of the original hashes in that group.
  def self.group_hashes(hashes, group_by_keys, group_result_key = :data)
    grouped = hashes.group_by { |h| h.slice(*group_by_keys) }

    grouped.map do |k, v|
      k.merge(group_result_key => v)
    end
  end
end
