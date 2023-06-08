import sys
from markus_exam_matcher.image_processing import read_chars
from markus_exam_matcher.core.char_types import CharType


if __name__ == '__main__':
  img_path = sys.argv[1]
  char_type = sys.argv[2]

  if char_type == 'digit':
    pred = read_chars.run(img_path, CharType.DIGIT, debug=False)
  else:
    assert char_type == 'letter'
    pred = read_chars.run(img_path, CharType.LETTER, debug=False)

  print(pred)
