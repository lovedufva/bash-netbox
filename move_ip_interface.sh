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

# Get address id from netbox
addrIdJson=$(curl -s -H "Authorization: Token "$token"" \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
"$nb_url"/graphql/ \
--data '{"query": "query {ip_address_list(address:\"'$ADDR'\") {id}}"}' )

# Set some variables for the API call
addrId=$(echo "$addrIdJson" | jq -r '.data.ip_address_list[].id' )
unicodeFixed=$(echo $addrId | tr -d $'\u00a0')

echo "$nb_url/ipam/ip-addresses/import/"
echo "id,device,interface"
echo "$unicodeFixed,$DEVICE,$INTERFACE"

##### TODO make "jsonData" variable happen

exit 0

##### 

# Update ip interface assignment in netbox

#curl -X 'PATCH' -H "Authorization: Token "$token"" \
#-H "Content-Type: application/json" \
#-H "Accept: application/json" \
#"$nb_url/api/ipam/ip-addresses/$unicodeFixed/" \
#--data "$jsonData"
