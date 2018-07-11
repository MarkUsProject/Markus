module UTF8Encoding
  # MarkUs extensions to the String class.
  module String
    def utf8_encode(src_encoding)
      if src_encoding
        self.encode Encoding::UTF_8, src_encoding
      else
        self
      end
    end
  end
end
