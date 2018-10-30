module ActiveRecordCreator

  # Return an active record id from a hash of attributes, or nil if it can't be found.
  # One can either pass an active record object in +attrs[symbol]+, or an id in +attrs[symbol_id]+ (an active record
  # object has precedence).
  def get_id_attr(symbol, attrs)
    obj = attrs[symbol]
    if obj.nil?
      symbol = "#{symbol.to_s}_id".to_sym
      attrs[symbol]
    else
      obj.id
    end
  end

  # Return an active record id from a hash of attributes, or raise an ArgumentError if it can't be found.
  # One can either pass an active record object in +attrs[symbol]+, or an id in +attrs[symbol_id]+ (an active record
  # object has precedence).
  def get_id_attr!(symbol, attrs)
    id = get_id_attr(symbol, attrs)
    if id.nil?
      raise ArgumentError("#{symbol} or #{symbol}_id is required")
    end
    id
  end

end
