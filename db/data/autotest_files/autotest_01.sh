#!/bin/bash

# This is a test script that writes hard coded test outputs.
# Its purpose is for testing the autotester itself and should
# not be used as a model for real test script files.

# Unlike a real test script, this file does not read or
# interact in any way with the student files.


cat <<EOF
<test>
    <name>test_1</name>
    <input>input string</input>
    <expected>expected result value</expected>
    <actual>actual result value</actual>
    <marks_earned>5</marks_earned>
    <marks_total>5</marks_total>
    <status>pass</status>
</test>
<test>
    <name>test_2</name>
    <input>input string</input>
    <expected>expected result value</expected>
    <actual>actual result value</actual>
    <marks_earned>0</marks_earned>
    <marks_total>5</marks_total>
    <status>fail</status>
</test>
<test>
    <name>test_1</name>
    <input>input string</input>
    <expected>expected result value</expected>
    <actual>actual result value</actual>
    <marks_earned>3</marks_earned>
    <marks_total>5</marks_total>
    <status>partial</status>
</test>
<test>
    <name>test_1</name>
    <input>input string</input>
    <expected>expected result value</expected>
    <actual>actual result value</actual>
    <marks_earned>0</marks_earned>
    <marks_total>5</marks_total>
    <status>error</status>
</test>
EOF
