#!/usr/bin/env bash

SCAN_INTERVAL="${SCAN_INTERVAL:-300}"
API_KEY="${API_KEY}"

while true
do

  # Scanning schedule
  echo "Scanning interval: $SCAN_INTERVAL"
  sleep "$SCAN_INTERVAL"

  # Log all scanned resources in a folder based on timestamp
  TIME_STAMP=$(date +%Y-%m-%d_%H-%M-%S)
  echo "Scanning timestamp: $TIME_STAMP"
  mkdir -p /kubescanner/scan_$TIME_STAMP

  # Dump all resources per namespace in json format
  for NS_NAME in `kubectl get ns -o=jsonpath='{.items[*].metadata.name}'`
  do

    # Skipping kube-system and other system namespace
    if [ "$NS_NAME" == "kube-system" ] || [ "$NS_NAME" == "kube-public" ] || [ "$NS_NAME" == "kube-node-lease" ]
    then
      continue
    fi

    echo "Scanning $NS_NAME namespace..."
    sleep 1
    echo "Dumping all resources in $NS_NAME namespace"
    sleep 1
    kubectl -n $NS_NAME get all -o json > /kubescanner/scan_$TIME_STAMP/$NS_NAME.json

  done

  for file in `ls /kubescanner/scan_$TIME_STAMP/`
  do
    echo "Processing $file into JSON array"
    sleep 1
    jq -s '{"apikey": "'$API_KEY'", "timestamp": "'$TIME_STAMP'", inventory: {items: . }}' sample-json/*.json > inventory.json
  done

  # Posting inventory.json to API end-point with API_KEY auth
  echo "Posting to the API endpoint"
  sleep 1
#  curl -v -H @{'apikey' = "$API_KEY"} $API_ENDPOINT -d @inventory.json --header "Content-Type: application/json"

  echo "Going to sleep till next scan"
  sleep 1

done
