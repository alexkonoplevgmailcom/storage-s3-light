#!/bin/bash

# BFB AWSS3Light Storage - Test Script
# This script runs the S3 storage test application

set -e

echo "🧪 Running NextGen PowerToys S3 Light Tests..."
echo "=============================================="

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
/opt/homebrew/Cellar/dotnet@8/8.0.18/bin/dotnet build --verbosity minimal

# Run tests
echo "🚀 Running S3 storage tests with .NET 8..."
echo ""
echo '' | /opt/homebrew/Cellar/dotnet@8/8.0.18/bin/dotnet run

echo ""
echo "🎉 Tests completed!"