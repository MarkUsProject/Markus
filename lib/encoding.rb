##
# MarkUs extensions to the String class.
class String
  def utf8_encode src_encoding
    if src_encoding
      self.encode Encoding::UTF_8, src_encoding
    else
      self
    end
  end
end

##
# We need to wrap a number of other duck types which
# can end up in places where strings or files are wanted

class File
  def utf8_encode src_encoding
    read.utf8_encode src_encoding
  end
end

class StringIO
  def utf8_encode src_encoding
    string.utf8_encode src_encoding
  end
end

class ActionDispatch::Http::UploadedFile
  def utf8_encode src_encoding
    read.utf8_encode src_encoding
  end
end

