#!/bin/bash

# Terraform S3 Backend Query Script
# Usage: ./queries/list-s3-backends.sh [directory]
# Lists all S3 backend configurations in terraform files

set -euo pipefail

# Default to current directory if none specified
SEARCH_DIR="${1:-.}"

# Check if directory exists
if [[ ! -d "$SEARCH_DIR" ]]; then
    echo "Error: Directory '$SEARCH_DIR' not found"
    exit 1
fi

# Print table header
printf "%-40s %-30s %-50s %-15s\n" "FILE" "BUCKET" "KEY" "REGION"
printf "%-40s %-30s %-50s %-15s\n" "----" "------" "---" "------"

# Find and parse terraform files
if ! find "$SEARCH_DIR" -name "*.tf" -type f -exec awk '
/backend "s3"/ { in_block=1; file=FILENAME }
in_block {
    if (match($0, /bucket[[:space:]]*=[[:space:]]*"([^"]+)"/, arr)) bucket=arr[1]
    if (match($0, /key[[:space:]]*=[[:space:]]*"([^"]+)"/, arr)) key=arr[1]
    if (match($0, /region[[:space:]]*=[[:space:]]*"([^"]+)"/, arr)) region=arr[1]
}
/^\s*}\s*$/ && in_block {
    # Truncate long values for display
    display_file = file
    if (length(display_file) > 40) display_file = substr(display_file, 1, 37) "..."
    if (length(bucket) > 30) bucket = substr(bucket, 1, 27) "..."
    if (length(key) > 50) key = substr(key, 1, 47) "..."
    if (length(region) > 15) region = substr(region, 1, 12) "..."
    
    printf "%-40s %-30s %-50s %-15s\n", display_file, bucket, key, region
    in_block=0; bucket=""; key=""; region=""
}
' {} + 2>/dev/null; then
    echo "No terraform files with S3 backends found"
    exit 0
fi
