#!/bin/bash


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
    <marks_earned>1</marks_earned>
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
    <marks_earned>9</marks_earned>
    <marks_total>5</marks_total>
    <status>error</status>
</test>
EOF
