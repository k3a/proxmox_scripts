#!/bin/bash
# Useful for graceful shutdowns and reboots of swarm nodes. Attempt 1 to tackle database corruption issues. Use with systemd service 
# Set your Docker API endpoint
DOCKER_API="10.1.20.220:55443"

# hostname matches node ID/name in Docker Swarm, otherwise edit
NODE_ID=$(hostname)

# Fetch current node version and role
API_RESPONSE=$(curl -s "$DOCKER_API/nodes/$NODE_ID")
NODE_VERSION=$(echo "$API_RESPONSE" | jq -r '.Version.Index')
NODE_ROLE=$(echo "$API_RESPONSE" | jq -r '.Spec.Role')

# Check node version and role successfully retrieved
if [ -z "$NODE_VERSION" ] || [ "$NODE_VERSION" == "null" ] || [ -z "$NODE_ROLE" ] || [ "$NODE_ROLE" == "null" ]; then
    echo "Failed to retrieve the node version or role for $NODE_ID."
    exit 1
fi

# Construct API endpoint for updating the node
UPDATE_ENDPOINT="$DOCKER_API/nodes/$NODE_ID/update?version=$NODE_VERSION"

# JSON payload to update the node status. Modify to switch between "drain" and "active"
PAYLOAD="{\"Availability\":\"active\",\"Role\":\"$NODE_ROLE\"}"

# Execute command to update node
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$UPDATE_ENDPOINT" -H "Content-Type: application/json" -d "$PAYLOAD")

# Check for successful response code (200-299)
if [[ $RESPONSE =~ ^2 ]]; then
    echo "Node $NODE_ID has been successfully updated to 'active' with role $NODE_ROLE."
else
    echo "Failed to update the node: HTTP status $RESPONSE"
    exit 1
fi
