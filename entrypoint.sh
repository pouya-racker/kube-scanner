#!/usr/bin/env bash

# List of resources that will be scanned
RESOURCE=(
  deployment
  service
  ingress
  pod
)

# Set scanning interval, defaulting to 300 if SCAN_INTERVAL env var is not passed in
SCAN_INTERVAL="${SCAN_INTERVAL:-300}"

# Set API_Key acting as auth token with portal
API_KEY="${API_KEY}"

# Looping through namespaces and scanning resources
while true
do

  # Scanning schedule
  echo "Scanning interval: $SCAN_INTERVAL"
  sleep "$SCAN_INTERVAL"

  # Log all scanned resources in a folder based on timestamp(epoch time)
  TIME_STAMP=$(date +%s)
  echo "Scanning timestamp: $TIME_STAMP"
  mkdir -p /kubescanner/scan_$TIME_STAMP

  # Dump all resources per namespace in json format
  for NS_NAME in $(kubectl get ns -o=jsonpath='{.items[*].metadata.name}')
  do

    # Skipping kube-system and other system namespace
    if [ "$NS_NAME" == "kube-system" ] || [ "$NS_NAME" == "kube-public" ] || [ "$NS_NAME" == "kube-node-lease" ]
    then
      continue
    fi

    echo "scanning namespace '${NS_NAME}'"
    sleep 1

    for resource in "${RESOURCE[@]}"
    do
        echo "scanning resource '${resource}'"
        for item in $(kubectl get "$resource" -n "$NS_NAME" 2>&1 | tail -n +2 | awk '{print $1}')
        do
            echo "exporting item '${item}'"
            kubectl -n "$NS_NAME" apply view-last-applied "$resource" "$item" -o json > /kubescanner/scan_$"TIME_STAMP"/$"NS_NAME".json
        done
    done

  done

  for file in `ls /kubescanner/scan_$TIME_STAMP/`
  do
    echo "Processing $file into JSON array"
    sleep 1
    jq -s '{ "data": { "timestamp": '$TIME_STAMP', "Description": "K8S scanning agent", inventory: { items: . }} }' /kubescanner/scan_$TIME_STAMP/*.json > /kubescanner/scan_$TIME_STAMP/inventory.json
  done

  # Posting inventory.json to API end-point with API_KEY auth
  echo "Posting to the API endpoint"
  sleep 1

  CURL_CMD="curl --location --request POST $API_ENDPOINT --header 'x-access-token: $API_KEY' --header 'Content-Type: application/json' -d @/kubescanner/scan_$TIME_STAMP/inventory.json"
  eval $"CURL_CMD"

  echo "Going to sleep till next scan"
  echo
  sleep 1

done