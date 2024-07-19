#!/bin/bash

# Install yq for parsing YAML files if not already installed
if ! command -v yq &> /dev/null; then
    echo "yq could not be found, installing..."
    sudo wget https://github.com/mikefarah/yq/releases/download/v4.6.3/yq_linux_amd64 -O /usr/bin/yq
    sudo chmod +x /usr/bin/yq
fi

# Install jq for JSON processing if not already installed
if ! command -v jq &> /dev/null; then
    echo "jq could not be found, installing..."
    sudo apt-get update
    sudo apt-get install -y jq
fi

# Define paths
#CONFIG_FILE="/opt/rtsp-samsung-tv/config-files/streams.yml"
#JSON_TEMPLATE="/opt/rtsp-samsung-tv/config-files/userChannels-template.json"
#OUTPUT_DIR="/opt/rtsp-samsung-tv/config-files/generated_configs"
#COMPOSE_FILE="/opt/rtsp-samsung-tv/docker-compose.yml"
CONFIG_FILE="./config-files/streams.yml"
JSON_TEMPLATE="./config-files/userChannels-template.json"
OUTPUT_DIR="./config-files/generated_configs"
COMPOSE_FILE="./docker-compose.yml"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Read the YAML file and convert it to JSON
containers=$(yq eval -j "$CONFIG_FILE")

# Generate userChannels.json for each container
echo "Generating userChannels.json files..."
echo "$containers" | jq -c '.containers[]' | while read -r container; do
    name=$(echo "$container" | jq -r '.name')
    streamUrl=$(echo "$container" | jq -r '.streamUrl')

    # Generate userChannels.json
    json_output="$OUTPUT_DIR/$name/userChannels.json"
    mkdir -p "$(dirname "$json_output")"
    jq --arg streamUrl "$streamUrl" '.channels[0].streamUrl = $streamUrl' "$JSON_TEMPLATE" > "$json_output"
done

# Generate docker-compose.yml
echo "Generating docker-compose.yml..."
{
  echo "version: '3.8'"
  echo "services:"
  echo "$containers" | jq -r '.containers[] | "  \(.name):\n    image: rtsp-samsung-tv:1.0.0\n    container_name: \(.name)\n    volumes:\n      - ./config-files/generated_configs/\(.name)/userChannels.json:/root/.rtsp/userChannels.json\n    ports:\n      - \(.webPort):3004\n      - \(.wsPort):9999\n"'
} > "$COMPOSE_FILE"

# Stop existing Docker containers
echo "Stopping existing Docker containers..."
docker-compose -f "$COMPOSE_FILE" down

# Start the Docker containers
echo "Starting Docker containers..."
#docker-compose -f "$COMPOSE_FILE" up -d
docker-compose -f "$COMPOSE_FILE" up --build
