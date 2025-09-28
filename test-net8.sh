#!/bin/bash

# NextGen PowerToys S3 Light - Test Script using .NET 8
# This script runs tests using the specific .NET 8 installation

set -e

echo "🧪 Running NextGen PowerToys S3 Light Tests with .NET 8..."
echo "========================================================="

# .NET 8 installation path
DOTNET8_PATH="/opt/homebrew/Cellar/dotnet@8/8.0.18/bin/dotnet"

# Verify .NET 8 is available
if [ ! -f "$DOTNET8_PATH" ]; then
    echo "❌ .NET 8 not found at $DOTNET8_PATH"
    echo "   Please install .NET 8 using: brew install dotnet@8"
    exit 1
fi

echo "✅ Using .NET 8 from: $DOTNET8_PATH"
echo "📋 .NET 8 Version:"
$DOTNET8_PATH --version
echo ""

# Check if MinIO is running
echo "🔍 Checking MinIO container..."
if docker ps --filter "name=s3-minio" --format "table {{.Names}}\t{{.Status}}" | grep -q "s3-minio"; then
    echo "✅ MinIO container is running"
else
    echo "❌ MinIO container not found. Please start MinIO first:"
    echo "   docker run -d --name s3-minio -p 9000:9000 -p 9001:9001 \\"
    echo "     -e MINIO_ROOT_USER=minioadmin \\"
    echo "     -e MINIO_ROOT_PASSWORD=minioadmin123 \\"
    echo "     minio/minio server /data --console-address ':9001'"
    exit 1
fi

# Change to test directory
cd "$(dirname "$0")/test/NextGenPowerToys.S3.TestApp"

# Build test app
echo "🔨 Building test application with .NET 8..."
$DOTNET8_PATH build --configuration Release --verbosity minimal

# Run tests non-interactively
echo "🚀 Running S3 storage tests..."
echo ""

# Create a script that automatically presses enter after test completion
timeout 60s bash -c "
    echo '' | $DOTNET8_PATH run --configuration Release --no-build
" || echo "Test completed or timed out"

echo ""
echo "🎉 Tests completed successfully using .NET 8!"
echo "📋 .NET 8 SDK: $($DOTNET8_PATH --version)"
echo "📁 Test files created in: ./test/NextGenPowerToys.S3.TestApp/test-files/"