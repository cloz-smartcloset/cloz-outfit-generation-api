#!/bin/bash

# Cloz Outfit Generator API - CI/CD Deployment Script
# This script automates the deployment process using AWS CodeBuild

set -e

# Configuration
STACK_NAME="cloz-outfit-generator-build"
REGION="eu-west-3"
LAMBDA_FUNCTION_NAME="ClozRandomLookGenerator"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if AWS CLI is configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "AWS CLI is configured"
}

# Function to create source code package
create_source_package() {
    print_status "Creating source code package..."
    
    # Remove existing package
    rm -f source.zip
    
    # Create source package (exclude build artifacts and unnecessary files)
    zip -r source.zip . -x "*.git*" "*.zip" "node_modules/*" "build/*" "deploy/*" "*.md" "test/*" ".env*"
    
    if [ -f source.zip ]; then
        print_success "Source package created: $(du -h source.zip | cut -f1)"
    else
        print_error "Failed to create source package"
        exit 1
    fi
}

# Function to deploy CloudFormation stack
deploy_stack() {
    print_status "Deploying CloudFormation stack: $STACK_NAME"
    
    # Check if stack exists
    if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION &> /dev/null; then
        print_status "Stack exists, updating..."
        aws cloudformation update-stack \
            --stack-name $STACK_NAME \
            --template-body file://build/cloudformation.yml \
            --parameters ParameterKey=ProjectName,ParameterValue=cloz-outfit-generator-build \
                        ParameterKey=SourceCodeBucket,ParameterValue=cloz-outfit-generator-source-$(date +%s) \
                        ParameterKey=ArtifactsBucket,ParameterValue=cloz-outfit-generator-artifacts-$(date +%s) \
                        ParameterKey=LambdaFunctionName,ParameterValue=$LAMBDA_FUNCTION_NAME \
            --capabilities CAPABILITY_NAMED_IAM \
            --region $REGION
        
        print_status "Waiting for stack update to complete..."
        aws cloudformation wait stack-update-complete --stack-name $STACK_NAME --region $REGION
    else
        print_status "Stack does not exist, creating..."
        aws cloudformation create-stack \
            --stack-name $STACK_NAME \
            --template-body file://build/cloudformation.yml \
            --parameters ParameterKey=ProjectName,ParameterValue=cloz-outfit-generator-build \
                        ParameterKey=SourceCodeBucket,ParameterValue=cloz-outfit-generator-source-$(date +%s) \
                        ParameterKey=ArtifactsBucket,ParameterValue=cloz-outfit-generator-artifacts-$(date +%s) \
                        ParameterKey=LambdaFunctionName,ParameterValue=$LAMBDA_FUNCTION_NAME \
            --capabilities CAPABILITY_NAMED_IAM \
            --region $REGION
        
        print_status "Waiting for stack creation to complete..."
        aws cloudformation wait stack-create-complete --stack-name $STACK_NAME --region $REGION
    fi
    
    print_success "CloudFormation stack deployed successfully"
}

# Function to get stack outputs
get_stack_outputs() {
    print_status "Getting stack outputs..."
    
    SOURCE_BUCKET=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`SourceCodeBucketName`].OutputValue' \
        --output text)
    
    ARTIFACTS_BUCKET=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`ArtifactsBucketName`].OutputValue' \
        --output text)
    
    CODEBUILD_PROJECT=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`CodeBuildProjectName`].OutputValue' \
        --output text)
    
    print_success "Source bucket: $SOURCE_BUCKET"
    print_success "Artifacts bucket: $ARTIFACTS_BUCKET"
    print_success "CodeBuild project: $CODEBUILD_PROJECT"
}

# Function to upload source code
upload_source_code() {
    print_status "Uploading source code to S3..."
    
    aws s3 cp source.zip s3://$SOURCE_BUCKET/source.zip --region $REGION
    
    print_success "Source code uploaded successfully"
}

# Function to start build
start_build() {
    print_status "Starting CodeBuild project..."
    
    BUILD_ID=$(aws codebuild start-build \
        --project-name $CODEBUILD_PROJECT \
        --region $REGION \
        --query 'build.id' \
        --output text)
    
    print_success "Build started with ID: $BUILD_ID"
    print_status "You can monitor the build in the AWS Console or run:"
    echo "aws codebuild batch-get-builds --ids $BUILD_ID --region $REGION"
}

# Function to wait for build completion
wait_for_build() {
    print_status "Waiting for build to complete..."
    
    while true; do
        BUILD_STATUS=$(aws codebuild batch-get-builds \
            --ids $BUILD_ID \
            --region $REGION \
            --query 'builds[0].buildStatus' \
            --output text)
        
        case $BUILD_STATUS in
            "SUCCEEDED")
                print_success "Build completed successfully!"
                break
                ;;
            "FAILED"|"FAULT"|"STOPPED"|"TIMED_OUT")
                print_error "Build failed with status: $BUILD_STATUS"
                exit 1
                ;;
            *)
                print_status "Build status: $BUILD_STATUS, waiting..."
                sleep 30
                ;;
        esac
    done
}

# Function to deploy to Lambda
deploy_to_lambda() {
    print_status "Deploying to Lambda function..."
    
    # Download the artifact
    aws s3 cp s3://$ARTIFACTS_BUCKET/outfit-generator-build/outfit-generator.zip . --region $REGION
    
    # Update Lambda function
    aws lambda update-function-code \
        --function-name $LAMBDA_FUNCTION_NAME \
        --zip-file fileb://outfit-generator.zip \
        --region $REGION
    
    print_success "Lambda function updated successfully"
}

# Main execution
main() {
    print_status "Starting Cloz Outfit Generator API deployment..."
    
    # Check prerequisites
    check_aws_cli
    
    # Create source package
    create_source_package
    
    # Deploy CloudFormation stack
    deploy_stack
    
    # Get stack outputs
    get_stack_outputs
    
    # Upload source code
    upload_source_code
    
    # Start build
    start_build
    
    # Wait for build completion
    wait_for_build
    
    # Deploy to Lambda
    deploy_to_lambda
    
    print_success "Deployment completed successfully!"
    print_status "Your Lambda function has been updated with the latest code."
}

# Run main function
main "$@"
