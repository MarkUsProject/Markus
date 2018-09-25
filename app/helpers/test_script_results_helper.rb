module TestScriptResultsHelper
  def group_hash_list(hash_list, group_by_keys, sublist_key)
    new_hash_list = []
    hash_list.group_by { |g| g.values_at(*group_by_keys) }.values.each do |val|
      h = Hash.new
      group_by_keys.each do |key|
        h[key] = val[0][key]
      end
      h[sublist_key] = val
      new_hash_list<< h
    end
    new_hash_list
  end
end
