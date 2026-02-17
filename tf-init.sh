#!/bin/bash

# Terraform S3 Backend Initializer
# Usage: ./tf-init.sh --bucket my-bucket --key path/to/state

set -euo pipefail

# Function to display usage information
usage() {
    echo "Usage: $0 --bucket <bucket-name> --key <state-key> [--region <aws-region>]"
    echo ""
    echo "Required:"
    echo "  --bucket <name>     S3 bucket name for Terraform state"
    echo "  --key <path>        Path to state file in bucket (e.g., terraform.tfstate)"
    echo ""
    echo "Optional:"
    echo "  --region <region>   AWS region (default: eu-west-2)"
    echo "  --help, -h          Show this help message"
}

# Function to check if aws-cli is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "Error: aws-cli is not installed or not in PATH"
        exit 1
    fi
    echo "AWS CLI found: $(aws --version)"
}

# Function to check if Terraform is installed
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        echo "Error: Terraform is not installed or not in PATH"
        exit 1
    fi
    echo "Terraform found: $(terraform --version | head -n1)"
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
}

# Function to parse command line arguments
# Sets global variables: BUCKET, STATE_KEY, REGION
parse_args() {
    # Reset global variables
    BUCKET=""
    STATE_KEY=""
    REGION=""

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
                REGION="$2"
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

    # Set default region if not provided
    if [[ -z "${REGION:-}" ]]; then
        REGION="eu-west-2"
    fi
}

# Main function
main() {
    # Parse arguments (sets BUCKET and STATE_KEY)
    parse_args "$@"

    # Validate required arguments
    if [[ -z "${BUCKET:-}" ]]; then
        echo "Error: --bucket is required"
        exit 1
    fi

    if [[ -z "${STATE_KEY:-}" ]]; then
        echo "Error: --key is required"
        exit 1
    fi

    # Check prerequisites
    check_aws_cli
    verify_aws_auth
    check_terraform

    # Create isolated directory based on state key
    # Replace slashes with underscores for directory name
    local DIR_NAME=$(echo "$STATE_KEY" | tr '/' '_')
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
    region = "${REGION}"
  }
}
EOF

    echo "Backend configuration created:"
    echo "  Bucket: $BUCKET"
    echo "  Key: $STATE_KEY"
    echo "  Region: $REGION"
    echo "  Directory: $DIR_NAME"

    # Run terraform init
    echo ""
    echo "Running terraform init..."
    terraform init

    echo ""
    echo "Terraform initialized successfully in $DIR_NAME/"
}

# Execute main function
main "$@"
