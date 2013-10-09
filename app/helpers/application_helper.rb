# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  # A more robust flash method. Easier to add multiple messages of each type:
  # :error, :success, :warning and :notice
  def flash_message(type, text)
    available_types = [:error, :success, :warning, :notice]
    # If type isn't one of the four above, we display it as :notice.
    # We don't want to suppress the message, which is why we pick a
    # type, and :notice is the most neutral of the four
    type = :notice if !available_types.include?(type)
    # If a flash with that type doesn't exist, create a new array
    flash[type] = [] if !flash.key?(type)
    # If the message doesn't already exist, add it
    unless flash[type].include?(text)
      flash[type].push(text)
    end
  end

  # A version of flash_message using flash.now instead. This makes the flash
  # available only for the current action.
  def flash_now(type, text)
    available_types = [:error, :success, :warning, :notice]
    type = :notice if !available_types.include?(type)

    flash.now[type] = [] if flash.now[type].nil?
    unless flash.now[type].include?(text)
      flash.now[type].push(text)
    end
  end
end