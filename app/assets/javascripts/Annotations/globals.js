// Global variables currently used by the annotation code
// TODO: remove these!
var annotation_manager = null;

var ANNOTATION_TYPES = {
  CODE: 0,
  IMAGE: 1,
  PDF: 2,
  HTML: 3,
};

// Enum to tell the code if an image, code, or pdf is being shown
// in the codeviewer
var annotation_type;
