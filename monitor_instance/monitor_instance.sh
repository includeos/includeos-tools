#!/bin/bash

instance=${1?Please provide Instance ID to monitor}
timeout=${2?Please provide timeout variable (seconds)}
mothershipBin=${MB_MOTHERSHIP_BIN:-$GOPATH/src/github.com/includeos/mothership/mothership}
mothershipHost=${MB_MOTHERSHIP_HOST:-localhost}
mothershipUsername=${MB_MOTHERSHIP_USER?}
mothershipPassword=${MB_MOTHERSHIP_PWD?}
hook=${MB_WEBHOOK_URL?}

# Loop
old_log=""
loops=0
while true; do
  output=$($mothershipBin --host $mothershipHost --username $mothershipUsername --password $mothershipPassword inspect-instance $instance)
  if [ $? -ne 0 ]; then
    echo Mothership did not answer successfully
    exit 1
  fi
  new_log=$(printf "$output" | grep "Last Log")
  if [ "$old_log" == "$new_log" ]; then
    loops=$((loops+1))
  else
    old_log=$new_log
    loops=0
    printf "There was a new log entry\n"
  fi
  if [ "$loops" -gt "$timeout" ]; then
    echo Oh no
    curl -X POST -H 'Content-type: application/json' --data '{"text":"Instance: '$instance' has stopped"}' $hook 
    exit 1
  fi
  sleep 1
done
