# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # A more robust flash method. Easier to add multiple messages of each type:
  # :error, :success, :warning and :notice
  def flash_message(type, text = '', flash_type = flash, **kwargs)
    available_types = [:error, :success, :warning, :notice]
    # If type isn't one of the four above, we display it as :notice.
    # We don't want to suppress the message, which is why we pick a
    # type, and :notice is the most neutral of the four
    type = :notice unless available_types.include?(type)
    # If a flash with that type doesn't exist, create a new array
    flash_type[type] ||= []
    content = kwargs.empty? ? "<p>#{text.to_s.gsub(/\n/, '<br/>')}</p>" : render_to_string(**kwargs).split("\n").join
    # If the message doesn't already exist, add it
    flash_type[type].push(content) unless flash_type[type].include?(content)
  end

  # A version of flash_message using flash.now instead. This makes the flash
  # available only for the current action.
  def flash_now(type, text = '', **kwargs)
    flash_message(type, text, flash.now, **kwargs)
  end

  # A version of flash_message that accepts an ActionPolicy authorization result
  # instead of a message. The result is used to get failure messages and those
  # messages are added to the flash hash. If the result is a success, this method
  # does nothing. The result is then returned.
  def flash_allowance(type, result, flash_type = flash)
    message = result.reasons.full_messages.join("\n")
    message = result.message if message.blank?
    flash_message(type, message, flash_type) unless result.value
    result
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
end
