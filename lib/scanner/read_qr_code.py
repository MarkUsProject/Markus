import sys
import cv2
import zxingcpp


if __name__ == '__main__':
  input_filename = sys.argv[1]
  img = cv2.imread(input_filename)
  results = zxingcpp.read_barcodes(img)
  if len(results) == 0:
     print("Could not find any barcode.")
     sys.exit(1)
  else:
     result = results[0]
     print(result.text)
