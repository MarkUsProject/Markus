
module ClasslistParser
  
  # TODO Attributes should be dynamically transformed to symbols
  FIELDS = [:user_name, :user_number, :last_name, :first_name, :status, :role]
  
  # Add a new student user to the class list by matching each line of 
  # the file to the ordering of the value of the fields. If a line corresponds 
  # to a user with the same user_number, then existing user is updated with 
  # the values from the field.  
  # Note that delimiter is not space-aware, i.e. if line is "a, b, c, d" 
  # and you pass "," as delimiter, then you will get spaces with the values; 
  # pass ", " as delimiter instead.
  def parse(filename, delim=" ")
    return unless File.file?(filename) && File.readable?(filename)
    
    # convert each line to a hash with FIELDS as corresponding keys 
    # and create or update a user with the hash values
    File.foreach(filename) do |line|
      line.chomp!
      attr = {}
      FIELDS.zip(line.split(delim)) do |key, val|
        attr[key] = val.chomp if val
      end
      
      # If user with same user_number exists, then it is updated; 
      # otherwise we create a new user
      User.find_or_create_by_user_number(attr).save!
    end

  end
  
end

