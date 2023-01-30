#!/bin/bash
#
# Example site name: NY1.US, region name "New York"
# Create "geofeed" tag and assign it to prefixes you want to export
# This follows RFC 8805, but no support has been built for region or postal codes.
#
# Vars
token="NETBOX_TOKEN"
nb_url="https://netbox.example.com"
output_file="/var/www/example.com/geofeed.csv"

# Create csv file
touch $output_file
echo "# prefix,country_code,region,city,postal_code" > $output_file

# Get prefixes from netbox
prefixJson=$(curl -s -H "Authorization: Token "$token"" \
-H "Content-Type: application/json" \
-H "Accept: application/json" \
"$nb_url"/graphql/ \
--data '{"query": "query {prefix_list(tag:\"geofeed\") {prefix site {name region {name}}}}"}')

for row in $(echo "$prefixJson" | jq -r '.data.prefix_list[] | @base64'); do
    _jq() {
     echo "${row}" | base64 --decode | jq -r "${1}"
    }

    # OPTIONAL
    # Set each property of the row to a variable
    prefix=$(_jq '.prefix')
    country=$(_jq '.site.name' | sed -e 's/.*\.//')
    city=$(_jq '.site.region.name')

    # Utilize your variables
    echo "$prefix,$country,,$city," >> $output_file
done
