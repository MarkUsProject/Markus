# Helper methods for grade entry forms

module GradeEntryFormsHelper
  # Removes items that have empty names (so they don't get updated)
  def update_grade_entry_form_params(attributes)
    grade_entry_items =
      params[:grade_entry_form][:grade_entry_items_attributes]

    unless grade_entry_items.nil?
      # Delete items with empty name and out_of
      grade_entry_items.delete_if { |_, item| item[:name].empty? && item[:out_of].empty? }
      # Update the attributes hash
      max_position = 1
      grade_entry_items.each do |_, item|
        # Some items are being deleted so don't update those
        unless item[:_destroy] == 1
          item[:position] = max_position
          max_position += 1
        end
      end
    end
    attributes[:grade_entry_items_attributes] = grade_entry_items
    grade_entry_form_params(attributes)
  end

  private

  def grade_entry_form_params(attributes)
    attributes.require(:grade_entry_form)
              .permit(:description,
                      :message,
                      :due_date,
                      :show_total,
                      :short_identifier,
                      :is_hidden,
                      grade_entry_items_attributes: [:name,
                                                     :out_of,
                                                     :position,
                                                     :bonus,
                                                     :_destroy,
                                                     :id])
  end
end
