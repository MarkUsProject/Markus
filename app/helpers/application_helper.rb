# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # A more robust flash method. Easier to add multiple messages of each type:
  # :error, :success, :warning and :notice
  def flash_message(type, text = '', **kwargs)
    available_types = [:error, :success, :warning, :notice]
    # If type isn't one of the four above, we display it as :notice.
    # We don't want to suppress the message, which is why we pick a
    # type, and :notice is the most neutral of the four
    type = :notice unless available_types.include?(type)
    # If a flash with that type doesn't exist, create a new array
    flash[type] ||= []
    content = kwargs.empty? ? "<p>#{ text.to_s }</p>" : "#{ render_to_string(**kwargs) }".split("\n").join
    # If the message doesn't already exist, add it
    unless flash[type].include?(content)
      flash[type].push(content)
    end
  end

  # A version of flash_message using flash.now instead. This makes the flash
  # available only for the current action.
  def flash_now(type, text)
    available_types = [:error, :success, :warning, :notice]
    type = :notice unless available_types.include?(type)

    flash.now[type] ||= []
    text = text.to_s
    unless flash.now[type].include?(text)
      flash.now[type].push(text)
    end
  end

  def markdown(text)
    options = { filter_html: false, hard_wrap: true,
                link_attributes: { rel: 'nofollow', target: '_blank' },
                space_after_headers: true, fenced_code_blocks: true,
                escape_html: true }
    extensions = { autolink: true }
    renderer = Redcarpet::Render::HTML.new(options)
    markdown = Redcarpet::Markdown.new(renderer, extensions)
    return markdown.render(text).html_safe unless text.nil?
  end

  def yield_content!(content_key)
    view_flow.content.delete(content_key)
  end

  # Take a list of hashes (or an ActiveRecord Relation object)
  # and group them by group_by_keys. This will return a list
  # of hashes containing each key/value pair in group_by_keys
  # and the original data from that group as the value of the
  # sublist key:
  #
  # Ex:
  #
  # > data = [{:a=>1, :b=>2, :c=>4}, {:a=>1, :b=>2, :c=>4}, {:a=>2, :b=>4, :c=>4}, {:a=>2, :b=>3, :c=>4}]
  # > group_hash_list(data, [:a, :b], 'other')
  # [{:a=>1, :b=>2, "other"=>[{:a=>1, :b=>2, :c=>4}, {:a=>1, :b=>2, :c=>4}]},
  #  {:a=>2, :b=>4, "other"=>[{:a=>2, :b=>4, :c=>4}]},
  #  {:a=>2, :b=>3, "other"=>[{:a=>2, :b=>3, :c=>4}]}]
  def group_hash_list(hash_list, group_by_keys, sublist_key)
    new_hash_list = []
    hash_list.group_by { |g| g.values_at(*group_by_keys) }.values.each do |val|
      h = Hash.new
      group_by_keys.each do |key|
        h[key] = val[0][key]
      end
      h[sublist_key] = val
      new_hash_list << h
    end
    new_hash_list
  end
end
