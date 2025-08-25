#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_DIR/terraform"

# Default values
ENVIRONMENT="dev"
AWS_REGION="us-east-1"
SKIP_BUILD=false
SKIP_PUSH=false
SKIP_INFRA=false

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy Citrine with Directus to AWS

OPTIONS:
    -e, --environment ENV    Environment to deploy (dev, staging, prod) [default: dev]
    -r, --region REGION      AWS region [default: us-east-1]
    -s, --skip-build         Skip building Docker images
    -p, --skip-push          Skip pushing Docker images to ECR
    -i, --skip-infra         Skip infrastructure deployment
    -h, --help               Show this help message

EXAMPLES:
    $0 -e prod -r us-west-2
    $0 --environment staging --skip-build
    $0 --help

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -s|--skip-build)
            SKIP_BUILD=true
            shift
            ;;
        -p|--skip-push)
            SKIP_PUSH=true
            shift
            ;;
        -i|--skip-infra)
            SKIP_INFRA=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Must be dev, staging, or prod."
    exit 1
fi

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."

    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi

    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi

    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi

    print_status "Prerequisites check passed."
}

# Build Docker images
build_images() {
    if [[ "$SKIP_BUILD" == true ]]; then
        print_warning "Skipping Docker image build."
        return
    fi

    print_status "Building Docker images..."

    # Build Citrine image
    print_status "Building Citrine image..."
    docker build -t citrine:latest -f Server/deploy.Dockerfile .

    # Build Directus image
    print_status "Building Directus image..."
    docker build -t directus:latest -f DirectusExtensions/directus.Dockerfile .

    print_status "Docker images built successfully."
}

# Push images to ECR
push_images() {
    if [[ "$SKIP_PUSH" == true ]]; then
        print_warning "Skipping Docker image push."
        return
    fi

    print_status "Pushing Docker images to ECR..."

    # Get AWS account ID
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

    # Login to ECR
    print_status "Logging in to ECR..."
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

    # Tag and push Citrine image
    print_status "Pushing Citrine image..."
    docker tag citrine:latest "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ENVIRONMENT-citrine:latest"
    docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ENVIRONMENT-citrine:latest"

    # Tag and push Directus image
    print_status "Pushing Directus image..."
    docker tag directus:latest "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ENVIRONMENT-directus:latest"
    docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ENVIRONMENT-directus:latest"

    print_status "Docker images pushed successfully."
}

# Deploy infrastructure
deploy_infrastructure() {
    if [[ "$SKIP_INFRA" == true ]]; then
        print_warning "Skipping infrastructure deployment."
        return
    fi

    print_status "Deploying infrastructure with Terraform..."

    cd "$TERRAFORM_DIR"

    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init

    # Plan deployment
    print_status "Planning Terraform deployment..."
    terraform plan -var="environment=$ENVIRONMENT" -var="aws_region=$AWS_REGION"

    # Ask for confirmation
    read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled."
        exit 0
    fi

    # Apply deployment
    print_status "Applying Terraform deployment..."
    terraform apply -var="environment=$ENVIRONMENT" -var="aws_region=$AWS_REGION" -auto-approve

    print_status "Infrastructure deployed successfully."
}

# Main deployment function
main() {
    print_status "Starting Citrine with Directus deployment to AWS..."
    print_status "Environment: $ENVIRONMENT"
    print_status "AWS Region: $AWS_REGION"
    print_status "Project Directory: $PROJECT_DIR"

    # Check prerequisites
    check_prerequisites

    # Build images
    build_images

    # Push images
    push_images

    # Deploy infrastructure
    deploy_infrastructure

    print_status "Deployment completed successfully!"
    print_status "You can now access your application at the ALB DNS name shown in the Terraform output."
}

# Run main function
main "$@"
