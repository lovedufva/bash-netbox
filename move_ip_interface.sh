#!/bin/bash
#
# Vars
token="NETBOX_TOKEN"
nb_url="https://netbox.example.com"
# Functions
usage() {
	echo "Usage: $0 [ -a ADDRESS in quotes ('192.168.0.1/24') ] [ -d DEVICE (e.g. switch1.example.com) ] [ -i INTERFACE (Ethernet1/2) ]" 1>&2
}
exit_abnormal() {
  usage
  exit 1
}
# Getopts
while getopts ":a:d:i:" options; do
  case "${options}" in
    a)
      ADDR=${OPTARG}
      ;;
    d)
      DEVICE=${OPTARG}
      ;;
    i)
      INTERFACE=${OPTARG}
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

# Echo CSV base
echo "$nb_url/ipam/ip-addresses/import/"
echo "id,device,interface"

# Get address id from netbox
echo "$ADDR" | while read -d, addr || [[ -n $addr ]]; do
addrIdJson=$(curl -s -H "Authorization: Token "$token"" \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
"$nb_url"/graphql/ \
--data '{"query": "query {ip_address_list(address:\"'$addr'\") {id}}"}' )

# Sort out some stuff
addrId=$(echo "$addrIdJson" | jq -r '.data.ip_address_list[].id' )
unicodeFixed=$(echo $addrId | tr -d $'\u00a0')

echo "$unicodeFixed,$DEVICE,$INTERFACE"
done
