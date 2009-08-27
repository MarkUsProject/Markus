#!/bin/bash

STUDENT_LIST_BASE_NAME="student_list"
for i in `seq 5`; do
	# write 5 chunks of student lists
	for j in `seq 1000`; do
		echo "student_${j},first_name_${j},last_name_${j}" >> "${STUDENT_LIST_BASE_NAME}_upload_${i}.csv"
		echo "student_${j}" >> "${STUDENT_LIST_BASE_NAME}_${i}.txt"
	done
done
cat ${STUDENT_LIST_BASE_NAME}_upload_* > student_list_upload_all.csv
