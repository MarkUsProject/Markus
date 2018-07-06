module UTF8Encoding
  # MarkUs extensions to the File class.
  module File
    def utf8_encode(src_encoding)
      read.utf8_encode src_encoding
    end
  end
end
