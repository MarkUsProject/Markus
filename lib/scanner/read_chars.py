import cv2
import glob
import math
import os
import sys
import tempfile
import numpy as np
from PIL import Image
from scipy import ndimage
from cnn import get_num, get_name


BUF = 5

# Maximum number of filled points at which a character box is considered empty
EMPTY_SPACE_TOLERANCE = 10


def gap_left(hist, x, th, K=10):
    """
    Checks if this x-coordinate marks the start of a new word/block.
    :param hist: distribution of pixels.
    :param x: x-coordinate.
    :param th: threshold value.
    :param K: number of columns of empty pixels to consider as new word/block.
    :return: whether this x-coordinate marks the start of a new word/block.
    """
    gap = hist[x+1] > th
    for i in range(K):
        if x - i < 0:
            break
        gap = gap and (i > x or hist[x-i] <= th)
    return gap


def gap_right(hist, x, th, W, K=10):
    """
    Checks if this x-coordinate marks the end of a word/block.
    :param hist: distribution of pixels.
    :param x: x-coordinate.
    :param th: threshold value.
    :param K: number of columns of empty pixels to consider as new word/block.
    :return: whether this x-coordinate marks the end of a word/block.
    """
    gap = hist[x-1] > th
    for i in range(K):
        if x + i > W:
            break
        gap = gap and (x+i >= len(hist) or hist[x+i] <= th)
    return gap


def straighten(img):
    """
    Deskews the input image based on the largest contour.
    :param img: input image.
    :return: deskewed image.
    """
    contours, _ = cv2.findContours(img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)

    max_area = 0
    max_contour = None
    for contour in contours:
        area = cv2.contourArea(contour)
        if area > max_area:
            max_area = area
            max_contour = contour

    rect = cv2.minAreaRect(max_contour)
    angle = rect[2]

    if angle < -45:
        angle = (90 + angle)

    # rotate the image to deskew it
    (h, w) = img.shape[:2]
    center = (w // 2, h // 2)
    M = cv2.getRotationMatrix2D(center, angle, 1.0)
    rotated = cv2.warpAffine(threshed, M, (w, h), flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_REPLICATE)
    return rotated


def sort_contours(cnts):
    """
    Sorts the contours in left-to-right order (based on x coordinate).
    :param cnts: list of contours.
    :return: sorted contours.
    """
    # construct the list of bounding boxes and sort them from top to bottom
    bounding_boxes = [cv2.boundingRect(c) for c in cnts]
    (cnts, bounding_boxes) = zip(*sorted(zip(cnts, bounding_boxes), key=lambda b: b[1][0]))
    return (cnts, bounding_boxes)


def get_best_shift(img):
    """
    Finds x and y units to shift the image by so it is centered.
    :param img: input image.
    :return: best x and y units to shift by.
    """
    cy,cx = ndimage.measurements.center_of_mass(img)

    rows,cols = img.shape
    shiftx = np.round(cols/2.0-cx).astype(int)
    shifty = np.round(rows/2.0-cy).astype(int)

    return shiftx, shifty


def shift(img,sx,sy):
    """
    Shifts the image by the given x and y units.
    :param img: input image.
    :param sx: x units to shift by.
    :param sy: y units to shift by.
    :return: shifted image.
    """
    rows, cols = img.shape
    M = np.float32([[1, 0, sx], [0, 1, sy]])
    shifted = cv2.warpAffine(img, M, (cols, rows))
    return shifted


def process_num(gray):
    """
    Process an input image of a handwritten number in the same way the MNIST dataset was processed.
    :param gray: the input grayscaled image.
    :return: the processed image.
    """
    gray = cv2.resize(gray, (28, 28))
    # strip away empty rows and columns from all sides
    while np.sum(gray[0]) == 0:
        gray = gray[1:]
    while np.sum(gray[:, 0]) == 0:
        gray = np.delete(gray, 0, 1)
    while np.sum(gray[-1]) == 0:
        gray = gray[:-1]
    while np.sum(gray[:, -1]) == 0:
        gray = np.delete(gray, -1, 1)

    # reshape image to be 20x20
    rows, cols = gray.shape
    if rows > cols:
        factor = 20.0 / rows
        rows = 20
        cols = int(round(cols * factor))
    else:
        factor = 20.0 / cols
        cols = 20
        rows = int(round(rows * factor))
    gray = cv2.resize(gray, (cols, rows))

    # pad the image to be 28x28
    colsPadding = (int(math.ceil((28 - cols) / 2.0)), int(math.floor((28 - cols) / 2.0)))
    rowsPadding = (int(math.ceil((28 - rows) / 2.0)), int(math.floor((28 - rows) / 2.0)))
    gray = np.pad(gray, (rowsPadding, colsPadding), 'constant')

    # shift the image is the written number is centered
    shiftx, shifty = get_best_shift(gray)
    gray = shift(gray, shiftx, shifty)
    return gray


def process_char(gray):
    """
    Process an input image of a handwritten character in the same way the EMNIST dataset was processed.
    :param gray: the input grayscaled image.
    :return: the processed image.
    """
    gray = cv2.resize(gray, (128, 128))
    # thicken the lines in the image
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
    gray = cv2.dilate(gray, kernel, iterations=2)
    gray = cv2.erode(gray, kernel, iterations=1)

    gray = cv2.GaussianBlur(gray, (0, 0), 1)
    # strip away empty rows and columns from all sides
    while np.sum(gray[0]) == 0:
        gray = gray[1:]
    while np.sum(gray[:, 0]) == 0:
        gray = np.delete(gray, 0, 1)
    while np.sum(gray[-1]) == 0:
        gray = gray[:-1]
    while np.sum(gray[:, -1]) == 0:
        gray = np.delete(gray, -1, 1)

    # shift the image is the written character is centered
    shiftx, shifty = get_best_shift(gray)
    gray = shift(gray, shiftx, shifty)

    # reshape image to be 24x24 and pad with black pixels on all sides to get 28x28 output
    rows, cols = gray.shape
    pad = 2
    if rows > cols:
        length = rows
        rowsPadding = (pad, pad)
        colsPadding = (length - cols + pad, length - cols + pad)
    else:
        length = cols
        colsPadding = (pad, pad)
        rowsPadding = (length - rows + pad, length - rows + pad)
    gray = np.pad(gray, (rowsPadding, colsPadding), 'constant')
    gray = cv2.resize(gray, (28, 28))
    return gray


def find_boxes(img):
    """
    Detects box(square) shapes in the input image.
    :param img: input image.
    :return: image with outlines of boxes from the original image.
    """
    kernel_length = np.array(img).shape[1] // 75
    verticle_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (1, kernel_length))
    hori_kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (kernel_length, 1))
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))

    # Detect vertical and horizontal lines in the image
    img_temp1 = cv2.erode(img, verticle_kernel, iterations=2)
    verticle_lines_img = cv2.dilate(img_temp1, verticle_kernel, iterations=2)
    img_temp2 = cv2.erode(img, hori_kernel, iterations=2)
    horizontal_lines_img = cv2.dilate(img_temp2, hori_kernel, iterations=2)

    # Weighting parameters, this will decide the quantity of an image to be added to make a new image.
    alpha = 0.5
    beta = 1.0 - alpha
    # Add the vertical and horizontal lines images to get a third image as summation.
    img_final_bin = cv2.addWeighted(verticle_lines_img, alpha, horizontal_lines_img, beta, 0.0)
    img_final_bin = cv2.erode(~img_final_bin, kernel, iterations=2)
    (_, img_final_bin) = cv2.threshold(img_final_bin, 128, 255, cv2.THRESH_BINARY | cv2.THRESH_OTSU)
    return img_final_bin


def extract_char(img, crop_dir, num=True):
    """
    Takes a block of handwritten characters and prints the recognized output.
    :param img: input image of block of handwritten characters.
    :param num: if the characters are numeric.
    :return: a list of indices of where the spaces occur in the input.
    """
    img_final_bin = find_boxes(img)

    # Find contours for image, which should detect all the boxes
    contours, hierarchy = cv2.findContours(img_final_bin, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    (contours, boundingBoxes) = sort_contours(contours)

    # Find the convex hull of each contour to get the correct outline of the box/square
    new_contours = []
    for k in range(len(contours)):
        new_contours.append(cv2.convexHull(contours[k], returnPoints=True))

    box_num = 0
    reached_x = 0
    spaces = []

    for c in new_contours:
        x, y, w, h = cv2.boundingRect(c)
        # check if box's edges are less than half the height of image (not likely to be a box with handwritten char)
        if w < np.array(img).shape[0] // 2 or h < np.array(img).shape[0] // 2:
            continue
        # check if this is an inner contour who's area has already been covered by another contour
        if x + w // 2 < reached_x:
            continue
        # check the contour has a square-like shape
        if abs(w - h) < abs(min(0.5*w, 0.5*h)):
            box_num += 1
            cropped = img[y:y + h, x:x + w]
            resized = cv2.resize(cropped, (28, 28))

            # check if this is an empty box (space)
            pts = cv2.findNonZero(resized)
            if pts is None or len(pts) < EMPTY_SPACE_TOLERANCE:
                spaces.append(box_num)
                continue

            if num:
                new_img = process_num(cropped)
            else:
                new_img = process_char(cropped)
            cv2.imwrite(crop_dir + '/' + str(box_num).zfill(2) + '.png', new_img)
            reached_x = x + w

    return spaces


if __name__ == '__main__':
    input_filename = sys.argv[1]
    # read input and covert to grayscale
    img = cv2.imread(input_filename)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # invert image and thicken pixel lines
    th, threshed = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY_INV|cv2.THRESH_OTSU)
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
    threshed = cv2.dilate(threshed, kernel, iterations=3)
    threshed = cv2.erode(threshed, kernel, iterations=3)

    # deskew image
    # TODO: review the straighten function, which currently (sometimes?) rotates to vertical
    # instead of horizontal
    # rotated = straighten(threshed)
    rotated = threshed

    # find and draw the upper and lower boundary of each lines
    hist = cv2.reduce(rotated, 1, cv2.REDUCE_AVG).reshape(-1)

    th = 2
    H, W = img.shape[:2]
    uppers = [y for y in range(H-1) if hist[y]<=th and hist[y+1]>th]
    lowers = [y for y in range(H-1) if hist[y]>th and hist[y+1]<=th]

    for i in range(min(len(uppers), len(lowers))):
        # isolate each line of text
        line = threshed[uppers[i]-BUF:lowers[i]+BUF, 0:W].copy()

        hist = cv2.reduce(line, 0, cv2.REDUCE_AVG).reshape(-1)
        H, W = line.shape[:2]
        lefts = [x for x in range(W-1) if gap_left(hist, x, th)]
        rights = [x for x in range(W-1) if gap_right(hist, x, th, W)]

        line = rotated[uppers[i]-BUF:lowers[i]+BUF, 0:W].copy()

        # ensure first right coordinate is after first left coordinate
        while lefts[0] > rights[0]:
            rights.pop(0)
        # go through each connected word/box
        for j in range(min(len(lefts), len(rights))):
            # look for connected boxes that contain handwritten characters
            if rights[j] - lefts[j] > 5 * H:
                word = line[0:H, lefts[j]-BUF:rights[j]+BUF].copy()
                hist = cv2.reduce(word, 1, cv2.REDUCE_AVG).reshape(-1)

                with tempfile.TemporaryDirectory() as tmp_dir:
                    with tempfile.TemporaryDirectory(dir=tmp_dir) as img_dir:
                        spaces = extract_char(word, img_dir, num=False)
                        get_name(tmp_dir, img_dir, spaces)

                with tempfile.TemporaryDirectory() as tmp_dir:
                    with tempfile.TemporaryDirectory(dir=tmp_dir) as img_dir:
                        spaces = extract_char(word, img_dir, num=True)
                        get_num(tmp_dir, img_dir, spaces)
