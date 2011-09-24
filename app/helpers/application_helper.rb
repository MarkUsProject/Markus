# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  # Given an error object returned from a failed database update/save, returns
  # a nicely formatted string containing the errors.
  # Example: {:name => "can't be blank", :random => "is too random"} results in
  #          "Name can't be blank, and Random is too random"
  def reason_for_error(error)
    messages = []
    error.each do |key, value|
      messages << "#{key}".capitalize + " #{value}"
    end
    
    return messages.to_sentence + '.'
  end
end