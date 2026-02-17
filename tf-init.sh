#!/bin/bash

# Terraform S3 Backend Initializer
# Usage: ./tf-init.sh --bucket my-bucket --key path/to/state [--region us-east-1] [--profile default]

set -euo pipefail

# Default values
AWS_REGION="us-east-1"
AWS_PROFILE="default"
BUCKET=""
STATE_KEY=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --bucket)
            BUCKET="$2"
            shift 2
            ;;
        --state|--key)
            STATE_KEY="$2"
            shift 2
            ;;
        --region)
            AWS_REGION="$2"
            shift 2
            ;;
        --profile)
            AWS_PROFILE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 --bucket <bucket-name> --key <state-key> [options]"
            echo ""
            echo "Required:"
            echo "  --bucket <name>     S3 bucket name for Terraform state"
            echo "  --key <path>        Path to state file in bucket (e.g., terraform.tfstate)"
            echo ""
            echo "Optional:"
            echo "  --region <region>   AWS region (default: us-east-1)"
            echo "  --profile <name>    AWS profile (default: default)"
            echo "  --help, -h          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$BUCKET" ]]; then
    echo "Error: --bucket is required"
    exit 1
fi

if [[ -z "$STATE_KEY" ]]; then
    echo "Error: --key is required"
    exit 1
fi

# Generate backend.tf
echo "Generating backend.tf..."
cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket  = "${BUCKET}"
    key     = "${STATE_KEY}"
    region  = "${AWS_REGION}"
    profile = "${AWS_PROFILE}"
  }
}
EOF

echo "Backend configuration created:"
echo "  Bucket: $BUCKET"
echo "  Key: $STATE_KEY"
echo "  Region: $AWS_REGION"
echo "  Profile: $AWS_PROFILE"

# Run terraform init
echo ""
echo "Running terraform init..."
export AWS_PROFILE="$AWS_PROFILE"
terraform init

echo ""
echo "Terraform initialized successfully!"
