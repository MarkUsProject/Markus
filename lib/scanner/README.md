Handwriting classifier for reading handwritten student information from the cover of scanned exams. Both numeric and alphabetical character classification are supported.

The written characters must each be contained within their own box. The input image should be a cropped portion of the cover page that only contains the relevant student information. There should be no border or other markings/decorations in the input image. An example input image is included at 'student_info.jpg'.

The script is called using 'python3 read_chars.py <input image>'. When called on 'student_info.jpg', the output is:
GUSTAV
505794
MAHLER
444158
OOOLZSOGGL
0001250981
