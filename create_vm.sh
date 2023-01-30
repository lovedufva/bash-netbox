#!/bin/bash
#
# Creates VM, interface and ip address and ties them together.
# See usage example below
#
# Vars
token="NETBOX_TOKEN"
nb_url="https://netbox.example.com"
# Functions
usage() {
	echo "Usage: $0 [ -n NAME (e.g. vm1.example.com) ] [ -i INTERFACE (e.g. eth0) ] [ -c CPUs (e.g. 2) ] [ -C CLUSTER (e.g. proxmox) ] [ -m MEMORY (e.g. 4096) ] [ -a ADDRESS/NETMASK (e.g. 10.13.37.69/24) ]" 1>&2
}
exit_abnormal() {
  usage
  exit 1
}
# Getopts
while getopts ":n:i:c:C:m:a:" options; do
  case "${options}" in
    n)
      NAME=${OPTARG}
      ;;
    i)
      INTERFACE=${OPTARG}
      ;;
    c)
      CPUS=${OPTARG}
      ;;
    C)
      CLUSTER=${OPTARG}
      ;;
    m)
      MEMORY=${OPTARG}
      ;;
    a)
      ADDRESS=${OPTARG}
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

# Check if address is taken
getAddress=$(curl -s -H "Authorization: Token "$token"" \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
"$nb_url"/graphql/ \
--data '{"query": "query {ip_address_list(address:\"'$ADDRESS'\") { id }}"}')
addressId=$(echo "$getAddress" | jq -r '.data.ip_address_list[].id')

if [ -n "${addressId}" ]; then
    echo "Address is taken!"
    exit 1
fi

#get cluster id

getCluster=$(curl -s -H "Authorization: Token "$token"" \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
"$nb_url"/graphql/ \
--data '{"query": "query {cluster_list(name:\"'$CLUSTER'\") { id }}"}')
clusterId=$( echo "$getCluster" | jq -r '.data.cluster_list[].id')

if [ -z "${clusterId}" ]; then
    echo "Cluster not found!"
    exit 1
fi

#create vm and get vm id

vmId=$(curl -s -H "Authorization: Token "$token"" \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
"$nb_url"/api/virtualization/virtual-machines/ \
--data '{"name": "'$NAME'", "status": "active", "cluster": '$clusterId', "vcpus": '$CPUS', "memory": '$MEMORY'}' | jq -r '.id')

if [ -z "${vmId}" ]; then
    echo "VM creation failed!"
    exit 1
fi

#create interface and assign to vm

interfaceId=$(curl -s -H "Authorization: Token "$token"" \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
"$nb_url"/api/virtualization/interfaces/ \
--data '{"virtual_machine": '$vmId', "name": "'$INTERFACE'"}' | jq -r '.id')

if [ -z "${interfaceId}" ]; then
    echo "Interface creation failed!"
    exit 1
fi

#create the ip address

ipId=$(curl -s -H "Authorization: Token "$token"" \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
"$nb_url"/api/ipam/ip-addresses/ \
--data '{"address": "'$ADDRESS'", "assigned_object_type": "virtualization.vminterface", "assigned_object_id": '$interfaceId'}' | jq -r '.id')

if [ -z "${ipId}" ]; then
    echo "Address creation failed!"
    exit 1
fi

echo "VM: $nb_url/virtualization/virtual-machines/$vmId/"
echo "Interface: $nb_url/virtualization/interfaces/$interfaceId/"
echo "Address: $nb_url/ipam/ip-addresses/$ipId"
