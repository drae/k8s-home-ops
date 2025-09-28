#! /usr/bin/bash

INPUT_PATH=$(echo "${SLSKD_SCRIPT_DATA}" | jq -r .localDirectoryName)

echo "Starting import of folder from: ${INPUT_PATH}" >> /logs/post_download_log.txt

# wget is the only thing available in the slskd container
wget --post-data "path=${INPUT_PATH}" "http://'':${WRTAG_API_KEY}@${WRTAG_URL}/op/move"