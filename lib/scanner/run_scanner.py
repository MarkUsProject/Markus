import sys
from markus_exam_matcher.image_processing import read_chars
from markus_exam_matcher.core.char_types import CharType
from argparse import ArgumentParser


def config_arg_parser() -> ArgumentParser:
  """
  Configure a command line argument parser.
  :return: Command line argument parser.
  """
  # Initialize parser
  parser = ArgumentParser(
      prog='run_scanner.py',
      description='Predict handwritten characters in rectangular grids.'
  )

  # Positional arguments
  parser.add_argument(
      'image',
      type=str,
      help='Path to image to predict characters from.'
  )
  parser.add_argument(
      'char_type',
      choices=['digit', 'letter'],
      help='Type of character to classify. Only digits and letters are supported.'
  )

  # Optional arguments
  parser.add_argument(
      '-d',
      '--debug',
      action='store_true',
      help='Specify whether to run program with debug mode enabled.'
  )

  return parser


if __name__ == '__main__':
  # Parse command line arguments
  parser = config_arg_parser()
  args = parser.parse_args(sys.argv[1:])

  # Make prediction
  char_type = CharType.DIGIT if args.char_type == 'digit' else CharType.LETTER

  pred = read_chars.run(args.image, char_type=char_type, debug=args.debug)
  print(pred)
