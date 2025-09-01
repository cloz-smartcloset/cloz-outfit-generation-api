# 🚀 Cloz Outfit Generator API - CI/CD Setup

This folder contains the complete CI/CD pipeline configuration for deploying your Lambda function using AWS CodeBuild.

## 📁 Files Overview

- **`buildspec.yml`** - CodeBuild build specification
- **`cloudformation.yml`** - Infrastructure as Code template
- **`deploy.sh`** - Automated deployment script
- **`README.md`** - This documentation file

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Source Code   │───▶│   S3 Source     │───▶│   CodeBuild     │───▶│   Lambda        │
│   Repository    │    │   Bucket        │    │   Project       │    │   Function      │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   S3 Artifacts  │    │   CloudWatch    │
                       │   Bucket        │    │   Logs          │
                       └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI installed and configured**
   ```bash
   aws configure
   ```

2. **Appropriate AWS permissions** for:
   - CloudFormation
   - CodeBuild
   - S3
   - Lambda
   - IAM
   - CloudWatch Logs

### One-Command Deployment

```bash
# Make the script executable
chmod +x build/deploy.sh

# Run the automated deployment
./build/deploy.sh
```

## 📋 Manual Deployment Steps

If you prefer to deploy manually or need to troubleshoot:

### 1. Deploy Infrastructure

```bash
aws cloudformation create-stack \
  --stack-name cloz-outfit-generator-build \
  --template-body file://build/cloudformation.yml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region eu-west-3
```

### 2. Create Source Package

```bash
zip -r source.zip . -x "*.git*" "*.zip" "node_modules/*" "build/*" "deploy/*" "*.md" "test/*" ".env*"
```

### 3. Upload Source Code

```bash
# Get the source bucket name from CloudFormation outputs
SOURCE_BUCKET=$(aws cloudformation describe-stacks \
  --stack-name cloz-outfit-generator-build \
  --region eu-west-3 \
  --query 'Stacks[0].Outputs[?OutputKey==`SourceCodeBucketName`].OutputValue' \
  --output text)

aws s3 cp source.zip s3://$SOURCE_BUCKET/source.zip --region eu-west-3
```

### 4. Start Build

```bash
# Get the CodeBuild project name
PROJECT_NAME=$(aws cloudformation describe-stacks \
  --stack-name cloz-outfit-generator-build \
  --region eu-west-3 \
  --query 'Stacks[0].Outputs[?OutputKey==`CodeBuildProjectName`].OutputValue' \
  --output text)

aws codebuild start-build --project-name $PROJECT_NAME --region eu-west-3
```

### 5. Deploy to Lambda

```bash
# Get the artifacts bucket name
ARTIFACTS_BUCKET=$(aws cloudformation describe-stacks \
  --stack-name cloz-outfit-generator-build \
  --region eu-west-3 \
  --query 'Stacks[0].Outputs[?OutputKey==`ArtifactsBucketName`].OutputValue' \
  --output text)

# Download and deploy
aws s3 cp s3://$ARTIFACTS_BUCKET/outfit-generator-build/outfit-generator.zip .
aws lambda update-function-code \
  --function-name ClozRandomLookGenerator \
  --zip-file fileb://outfit-generator.zip \
  --region eu-west-3
```

## 🔧 Configuration

### Environment Variables

The build process uses these environment variables:

- **`LAMBDA_FUNCTION_NAME`** - Target Lambda function name
- **`AWS_DEFAULT_REGION`** - AWS region for deployment

### Build Specifications

The `buildspec.yml` defines the build process:

1. **Install Phase**: Install Node.js 18 and dependencies
2. **Pre-build Phase**: Environment validation
3. **Build Phase**: Create deployment package
4. **Post-build Phase**: Build completion and artifact preparation

### Build Artifacts

- **Source**: `source.zip` (your application code)
- **Output**: `outfit-generator.zip` (Lambda deployment package)
- **Cache**: `node_modules/` (dependency caching)

## 📊 Monitoring

### CloudWatch Logs

Build logs are available in CloudWatch:
- **Log Group**: `/aws/codebuild/cloz-outfit-generator-build`
- **Retention**: 30 days

### Build Status

Monitor build progress:
```bash
aws codebuild batch-get-builds --ids <BUILD_ID> --region eu-west-3
```

## 🔒 Security Features

- **S3 Bucket Encryption**: AES256 server-side encryption
- **Public Access Blocked**: All S3 buckets are private
- **IAM Least Privilege**: Minimal required permissions
- **SSL/TLS**: All connections use encryption

## 🚨 Troubleshooting

### Common Issues

1. **Build Fails During Install**
   - Check Node.js version compatibility
   - Verify `package.json` syntax
   - Ensure all dependencies are available

2. **Permission Denied**
   - Verify IAM role permissions
   - Check CloudFormation stack status
   - Ensure AWS CLI is properly configured

3. **Lambda Update Fails**
   - Verify function name exists
   - Check function status (not updating)
   - Ensure artifact download succeeded

### Debug Commands

```bash
# Check CloudFormation stack status
aws cloudformation describe-stacks --stack-name cloz-outfit-generator-build --region eu-west-3

# View build logs
aws logs describe-log-groups --log-group-name-prefix "/aws/codebuild" --region eu-west-3

# Check S3 bucket contents
aws s3 ls s3://<BUCKET_NAME> --region eu-west-3
```

## 🔄 Continuous Integration

### GitHub Actions Integration

To integrate with GitHub Actions, add this workflow:

```yaml
name: Deploy to AWS Lambda

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-west-3
      - name: Deploy
        run: |
          chmod +x build/deploy.sh
          ./build/deploy.sh
```

## 📈 Scaling Considerations

- **Build Time**: ~5-10 minutes for typical deployments
- **Artifact Size**: ~3-5MB deployment packages
- **Concurrent Builds**: Limited by CodeBuild quotas
- **Cost**: Pay-per-use pricing model

## 🆘 Support

For issues or questions:

1. Check CloudWatch logs for detailed error messages
2. Verify AWS service quotas and limits
3. Review IAM permissions and policies
4. Check CloudFormation stack events

---

**Happy Deploying! 🎉**
