#!/bin/bash

# Terraform S3 Backend Initializer
# Usage: ./tf-init.sh --bucket my-bucket --key path/to/state

set -euo pipefail

# Default values
BUCKET=""
STATE_KEY=""

# Function to display usage information
usage() {
    echo "Usage: $0 --bucket <bucket-name> --key <state-key>"
    echo ""
    echo "Required:"
    echo "  --bucket <name>     S3 bucket name for Terraform state"
    echo "  --key <path>        Path to state file in bucket (e.g., terraform.tfstate)"
    echo ""
    echo "Optional:"
    echo "  --help, -h          Show this help message"
}

# Function to check if aws-cli is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "Error: aws-cli is not installed or not in PATH"
        echo "Please install AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
    echo "AWS CLI found: $(aws --version)"
}

# Function to verify AWS authentication
verify_aws_auth() {
    echo "Verifying AWS credentials..."
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "Error: AWS authentication failed"
        echo "Please configure your AWS credentials using:"
        echo "  - aws configure"
        echo "  - Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)"
        echo "  - IAM role (if running on EC2/ECS/Lambda)"
        exit 1
    fi
    echo "AWS authentication verified"
    aws sts get-caller-identity
}

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
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
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

# Check prerequisites
check_aws_cli
verify_aws_auth

# Create isolated directory based on state key
# Replace slashes with underscores for directory name
DIR_NAME=$(echo "$STATE_KEY" | tr '/' '_')
mkdir -p "$DIR_NAME"
cd "$DIR_NAME"

echo "Working in isolated directory: $DIR_NAME"

# Generate backend.tf
echo "Generating backend.tf..."
cat > backend.tf << EOF
terraform {
  backend "s3" {
    bucket = "${BUCKET}"
    key    = "${STATE_KEY}"
  }
}
EOF

echo "Backend configuration created:"
echo "  Bucket: $BUCKET"
echo "  Key: $STATE_KEY"
echo "  Directory: $DIR_NAME"

# Run terraform init
echo ""
echo "Running terraform init..."
terraform init

echo ""
echo "Terraform initialized successfully in $DIR_NAME/"
