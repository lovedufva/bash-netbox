#!/bin/bash
#
# This script assumes your label series starts with "10"
# For example, label your first cable 100001
#
# Vars
token="NETBOX_TOKEN"
nb_url="https://netbox.example.com"
NUMBER=1
# Functions
usage() {
  echo "Usage: $0 [ -n NUMBER (how many cables you want) ]" 1>&2
}
exit_abnormal() {
  usage
  exit 1
}
# Getopts
while getopts ":n:" options; do
  case "${options}" in
    n)
      NUMBER=${OPTARG}
      ;;
    :)
      echo "Error: -${OPTARG} requires an argument."
      exit_abnormal
      ;;
    *)
      exit_abnormal
      ;;
  esac
done

# Get labels from netbox
labels=$(curl -s -H "Authorization: Token "$token"" \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
"$nb_url"/graphql/ \
--data '{"query": "query {cable_list(label__isw:\"10\") { label }}"}')

lastUsedLabel=$(echo "$labels" | sed -e 's/:[0-9]//g' | jq -r '.data.cable_list[].label' | sort | uniq | tail -n1)
nextLabel=$((lastUsedLabel+1))
COUNT=1
while [ $COUNT -le $NUMBER ]; do
  echo "$nextLabel"
  let nextLabel+=1
  let COUNT+=1
done
exit 0
