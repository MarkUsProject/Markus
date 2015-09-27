
class DateValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, value)
    if Time.zone.parse(value.to_s).nil? &&
       !record.read_attribute_before_type_cast(attribute).blank?
      record.errors.add attribute, I18n.t('date_validator.invalid_date')
      false
    end
  end

end
