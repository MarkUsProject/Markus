#!/bin/bash

# Number of times to run the test
count=100

# Path to the test file and specific test
test_file="spec/controllers/groups_controller_spec.rb"
test_name="#create_groups_when_students_work_alone when assignment.group_max = 1 creates groups for individual students"

for i in $(seq 1 $count)
do
  echo "Running test iteration $i"
  docker compose run --rm app bundle exec rspec $test_file -e "$test_name"
  if [ $? -ne 0 ]; then
    echo "Test failed on iteration $i"
    exit 1
  fi
done

echo "All $count iterations passed!"
