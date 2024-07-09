#!/bin/ash

ZONE_ID=""
API_TOKEN=""
RECORD_NAME=""

# Get the current IP address from checkip.amazonaws.com
CURRENT_IP=$(curl -s https://checkip.amazonaws.com/)

# Check if the IP was retrieved successfully
if [ -z "$CURRENT_IP" ]; then
  echo "Failed to retrieve the current IP address."
  exit 1
fi

# Get the DNS record ID for the given RECORD_NAME
RESPONSE=$(curl -s -X GET \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$RECORD_NAME")

# Extract the record ID from the response
RECORD_ID=$(echo "$RESPONSE" | awk -F'"id":"' '{print $2}' | awk -F'"' '{print $1}')
echo "RECORD_ID: ";
echo $RECORD_ID;

# Check if the record ID was retrieved successfully
if [ -z "$RECORD_ID" ]; then
  echo "Failed to retrieve the record ID for $RECORD_NAME."
  exit 1
fi

# Extract the current IP set in Cloudflare from the response
CF_IP=$(echo "$RESPONSE" | awk -F'"content":' '{print $2}' | awk -F'"' '{print $2}')

echo "CF_IP: ";
echo $CF_IP;

# Check if the IP addresses are the same
if [ "$CURRENT_IP" = "$CF_IP" ]; then
  echo "The IP address has not changed."
  exit 0
fi

# Update the DNS record in Cloudflare
UPDATE_RESPONSE=$(curl -s -X PUT \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{
  \"type\": \"A\",
  \"name\": \"$RECORD_NAME\",
  \"content\": \"$CURRENT_IP\",
  \"ttl\": 1,
  \"proxied\": false
}" \
  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID")

# Check if the update was successful
if echo "$UPDATE_RESPONSE" | grep -q '"success":true'; then
  echo "DNS record updated successfully to $CURRENT_IP"
else
  echo "Failed to update DNS record."
  echo "Response: $UPDATE_RESPONSE"
  exit 1
fi