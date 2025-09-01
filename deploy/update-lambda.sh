#!/bin/bash

# Deploy script for Cloz Outfit Generation API
# Updates existing ClozRandomLookGenerator Lambda function

set -e

echo "🚀 Deploying Cloz Outfit Generation API..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Go to the project root directory (parent of deploy folder)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "📁 Project root: $PROJECT_ROOT"
cd "$PROJECT_ROOT"

# Set AWS credentials if not already set
export AWS_REGION=${AWS_REGION:-"eu-west-3"}

# Function details
FUNCTION_NAME="ClozRandomLookGenerator"
HANDLER="src/handlers/outfit-generator.handler"
RUNTIME="nodejs18.x"
ROLE="arn:aws:iam::195275649388:role/ClozLambdaExecutionRole"

echo "📦 Installing dependencies..."
npm install --omit=dev

echo "📦 Creating deployment package..."
# Check if files exist before zipping
if [ ! -d "src" ]; then
    echo "❌ Error: src/ directory not found!"
    exit 1
fi

if [ ! -d "node_modules" ]; then
    echo "❌ Error: node_modules/ directory not found!"
    exit 1
fi

if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found!"
    exit 1
fi

echo "📁 Zipping files: src/, node_modules/, package.json"
zip -r outfit-generator.zip src/ node_modules/ package.json -x "*.git*" "*test*" "*.md" "deploy/*"

echo "📦 Deployment package created: outfit-generator.zip"
ls -la outfit-generator.zip

echo "⚡ Updating Lambda function code..."
aws lambda update-function-code \
  --function-name $FUNCTION_NAME \
  --zip-file fileb://outfit-generator.zip \
  --region $AWS_REGION

echo "⚙️  Updating Lambda function configuration..."
aws lambda update-function-configuration \
  --function-name $FUNCTION_NAME \
  --handler $HANDLER \
  --runtime $RUNTIME \
  --timeout 30 \
  --memory-size 512 \
  --region $AWS_REGION

echo "🔍 Verifying deployment..."
aws lambda get-function \
  --function-name $FUNCTION_NAME \
  --region $AWS_REGION \
  --query '{FunctionName:Configuration.FunctionName,Runtime:Configuration.Runtime,Handler:Configuration.Handler,LastModified:Configuration.LastModified}'

echo "✅ Deployment complete!"
echo "📊 Function URL: https://kym0gf4um7.execute-api.eu-west-3.amazonaws.com/outfit_generator"
echo ""
echo "🧪 Test endpoints:"
echo "GET  https://kym0gf4um7.execute-api.eu-west-3.amazonaws.com/outfit_generator/models"
echo "POST https://kym0gf4um7.execute-api.eu-west-3.amazonaws.com/outfit_generator/generate"
echo ""
echo "📝 View logs:"
echo "aws logs tail /aws/lambda/$FUNCTION_NAME --follow --region $AWS_REGION"

# Cleanup
rm -f outfit-generator.zip

echo "🎉 Ready to generate outfits!"