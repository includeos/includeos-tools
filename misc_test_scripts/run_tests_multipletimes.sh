#!/bin/bash

# author: Martin
# comments: check whether the test runs with a test.py or test.sh

for i in {1..100}; do
  #  out=$(./test.py 2>&1)
  #  out=$(./test.sh 2>&1)
    exit_status=$?
    if [[ $exit_status -eq 0 ]]; then
        printf "$i: OK \n"
        deployable=$((deployable+1))
    elif [[ ! $exit_status -eq 0 ]]; then
        printf "$i: nope \n"
        error=$((error+1))
        printf "%s\n" "$out"
        exit 0
    fi
done

echo
echo Deployable: $deployable
echo Error:         $error
