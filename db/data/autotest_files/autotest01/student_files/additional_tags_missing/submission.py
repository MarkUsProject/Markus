#!/usr/bin/env python

"""
This student submission file is used to test the autotester
It represents the test case where:

  The xml is missing non-necessary tag (<input>, could also be
  <expected> or <actual>)
"""

response = '''
<test>
    <name>bad_xml_additional_tags_missing</name>
    <expected>NA</expected>
    <actual>NA</actual>
    <marks_earned>2</marks_earned>
    <marks_total>2</marks_total>
    <status>pass</status>
</test>
'''

print(response)
