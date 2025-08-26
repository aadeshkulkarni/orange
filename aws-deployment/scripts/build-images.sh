#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"  # Go up two levels to reach citrineos-core root

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

Build Docker images for Citrine with Directus

OPTIONS:
    -t, --tag TAG           Tag for the images [default: latest]
    -p, --push              Push images to registry after building
    -r, --registry REGISTRY Registry to push to (ECR, Docker Hub, etc.)
    -h, --help              Show this help message

EXAMPLES:
    $0 -t v1.0.0
    $0 --tag staging --push --registry ecr
    $0 --help

EOF
}

# Default values
IMAGE_TAG="latest"
PUSH_IMAGES=false
REGISTRY=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -p|--push)
            PUSH_IMAGES=true
            shift
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
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

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."

    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install it first."
        exit 1
    fi

    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        print_error "Docker daemon is not running. Please start Docker first."
        exit 1
    fi

    # Check Docker buildx
    if ! docker buildx version &> /dev/null; then
        print_warning "Docker buildx not available. This may cause build issues."
        print_warning "Consider installing buildx: https://docs.docker.com/go/buildx/"
    fi

    # Check Docker version
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    print_status "Docker version: $DOCKER_VERSION"

    # Verify project structure
    verify_project_structure

    print_status "Prerequisites check passed."
}

# Verify project structure
verify_project_structure() {
    print_status "Verifying project structure..."

    cd "$PROJECT_DIR"

    # Check if we're in the right directory
    if [[ ! -d "Server" ]] || [[ ! -d "DirectusExtensions" ]]; then
        print_error "Invalid project structure. Expected Server/ and DirectusExtensions/ directories."
        print_error "Current directory: $(pwd)"
        print_error "Available directories:"
        ls -la || true
        exit 1
    fi

    # Check Dockerfiles
    if [[ ! -f "Server/deploy.Dockerfile" ]]; then
        print_error "Citrine Dockerfile not found at Server/deploy.Dockerfile"
        print_error "Available files in Server/:"
        ls -la Server/ || true
        exit 1
    fi

    if [[ ! -f "DirectusExtensions/directus.Dockerfile" ]]; then
        print_error "Directus Dockerfile not found at DirectusExtensions/directus.Dockerfile"
        print_error "Available files in DirectusExtensions/:"
        ls -la DirectusExtensions/ || true
        exit 1
    fi

    print_status "Project structure verified successfully."
}

# Build Citrine image
build_citrine() {
    print_status "Building Citrine image..."

    cd "$PROJECT_DIR"

    # Try to build with buildx first, fallback to legacy builder
    if docker buildx version &> /dev/null; then
        print_status "Using Docker buildx..."
        docker build \
            -t "citrine:$IMAGE_TAG" \
            -f Server/deploy.Dockerfile \
            .
    else
        print_warning "Using legacy Docker builder (buildx not available)"
        DOCKER_BUILDKIT=0 docker build \
            -t "citrine:$IMAGE_TAG" \
            -f Server/deploy.Dockerfile \
            .
    fi

    print_status "Citrine image built successfully: citrine:$IMAGE_TAG"
}

# Build Directus image
build_directus() {
    print_status "Building Directus image..."

    cd "$PROJECT_DIR"

    # Try to build with buildx first, fallback to legacy builder
    if docker buildx version &> /dev/null; then
        print_status "Using Docker buildx..."
        docker build \
            -t "directus:$IMAGE_TAG" \
            -f DirectusExtensions/directus.Dockerfile \
            .
    else
        print_warning "Using legacy Docker builder (buildx not available)"
        DOCKER_BUILDKIT=0 docker build \
            -t "directus:$IMAGE_TAG" \
            -f DirectusExtensions/directus.Dockerfile \
            .
    fi

    print_status "Directus image built successfully: directus:$IMAGE_TAG"
}

# Push images to registry
push_images() {
    if [[ "$PUSH_IMAGES" != true ]]; then
        print_warning "Skipping image push (use --push to enable)."
        return
    fi

    if [[ -z "$REGISTRY" ]]; then
        print_error "Registry not specified. Use --registry to specify where to push images."
        exit 1
    fi

    print_status "Pushing images to $REGISTRY..."

    case $REGISTRY in
        ecr)
            push_to_ecr
            ;;
        dockerhub)
            push_to_dockerhub
            ;;
        *)
            print_error "Unsupported registry: $REGISTRY"
            print_error "Supported registries: ecr, dockerhub"
            exit 1
            ;;
    esac
}

# Push to AWS ECR
push_to_ecr() {
    print_status "Pushing to AWS ECR..."

    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi

    # Get AWS account ID and region
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region || echo "us-east-1")

    print_status "AWS Account ID: $AWS_ACCOUNT_ID"
    print_status "AWS Region: $AWS_REGION"

    # Login to ECR
    print_status "Logging in to ECR..."
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

    # Tag and push Citrine image
    print_status "Pushing Citrine image to ECR..."
    docker tag "citrine:$IMAGE_TAG" "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/citrine:$IMAGE_TAG"
    docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/citrine:$IMAGE_TAG"

    # Tag and push Directus image
    print_status "Pushing Directus image to ECR..."
    docker tag "directus:$IMAGE_TAG" "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/directus:$IMAGE_TAG"
    docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/directus:$IMAGE_TAG"

    print_status "Images pushed to ECR successfully!"
    print_status "ECR Repository URLs:"
    print_status "  Citrine: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/citrine:$IMAGE_TAG"
    print_status "  Directus: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/directus:$IMAGE_TAG"
}

# Push to Docker Hub
push_to_dockerhub() {
    print_status "Pushing to Docker Hub..."

    # Check if logged in to Docker Hub
    if ! docker info | grep -q "Username"; then
        print_error "Not logged in to Docker Hub. Please run 'docker login' first."
        exit 1
    fi

    # Get Docker Hub username
    DOCKER_USERNAME=$(docker info | grep "Username" | awk '{print $2}')

    if [[ -z "$DOCKER_USERNAME" ]]; then
        print_error "Could not determine Docker Hub username. Please run 'docker login' first."
        exit 1
    fi

    print_status "Docker Hub Username: $DOCKER_USERNAME"

    # Tag and push Citrine image
    print_status "Pushing Citrine image to Docker Hub..."
    docker tag "citrine:$IMAGE_TAG" "$DOCKER_USERNAME/citrine:$IMAGE_TAG"
    docker push "$DOCKER_USERNAME/citrine:$IMAGE_TAG"

    # Tag and push Directus image
    print_status "Pushing Directus image to Docker Hub..."
    docker tag "directus:$IMAGE_TAG" "$DOCKER_USERNAME/directus:$IMAGE_TAG"
    docker push "$DOCKER_USERNAME/directus:$IMAGE_TAG"

    print_status "Images pushed to Docker Hub successfully!"
    print_status "Docker Hub Repository URLs:"
    print_status "  Citrine: $DOCKER_USERNAME/citrine:$IMAGE_TAG"
    print_status "  Directus: $DOCKER_USERNAME/directus:$IMAGE_TAG"
}

# Show image information
show_image_info() {
    print_status "Built images:"
    docker images | grep -E "(citrine|directus)" | grep "$IMAGE_TAG" || true
}

# Main function
main() {
    print_status "Starting Docker image build for Citrine with Directus..."
    print_status "Image tag: $IMAGE_TAG"
    print_status "Project directory: $PROJECT_DIR"

    # Check prerequisites
    check_prerequisites

    # Build images
    build_citrine
    build_directus

    # Show image information
    show_image_info

    # Push images if requested
    push_images

    print_status "Build process completed successfully!"
}

# Run main function
main "$@"
