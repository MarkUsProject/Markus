#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The student allocates 10 GB of memory
"""
import time

gb = 1024**3
big_byte_array = b"a"*(10*gb)

time.sleep(1) # give the calling process a chance to do something

response = '''
<test>
    <name>memory_alloc_test</name>
    <input>NA</input>
    <expected>NA</expected>
    <actual>script was allowed to allocate 10GB of memory</actual>
    <marks_earned>0</marks_earned>
    <marks_total>2</marks_total>
    <status>fail</status>
</test>
'''

print(response)
