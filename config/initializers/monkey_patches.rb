# add monkey patches
String.include UTF8Encoding::String
StringIO.include UTF8Encoding::StringIO
File.include UTF8Encoding::File
ActionDispatch::Http::UploadedFile.include UTF8Encoding::File
