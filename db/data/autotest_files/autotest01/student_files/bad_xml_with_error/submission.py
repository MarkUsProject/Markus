#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The xml is malformed and also something writes to stderr
"""
import sys

sys.stderr.write('some error')

response = '''
<test>
    <name>bad_xml_simple</name
    <input>NA</input>
    <expected>NA</expected>
    <actual>NA</actual>
    <marks_earned>2</marks_earned>
    <marks_total>2</marks_total>
    <status>pass</status>
</test>
'''

print(response)
