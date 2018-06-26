module UTF8Encoding

  # MarkUs extensions to the StringIO class.
  module StringIO
    def utf8_encode(src_encoding)
      string.utf8_encode src_encoding
    end
  end
end
