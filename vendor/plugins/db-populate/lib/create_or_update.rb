class ActiveRecord::Base
  # given a hash of attributes including the ID, look up the record by ID.
  # uses whatever the PK of the model is to do the lookup 
  # If it does not exist, it is created with the rest of the options. 
  # If it exists, it is updated with the given options. 
  #
  # Raises an exception if the record is invalid to ensure seed data is loaded correctly.
  # 
  # Returns the record.
  def self.create_or_update(options = {})
    id = options.delete(primary_key.to_sym)
    record = send("find_by_#{primary_key}", id) || new
    record.id = id
    record.attributes = options
    record.save!
    
    record
  end
end