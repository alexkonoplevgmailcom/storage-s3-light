#!/bin/bash

# BFB AWSS3Light Storage - Build Script
# This script builds the standalone S3 storage NuGet package

set -e

echo "🏗️  Building BFB AWSS3Light Storage S3 Package..."
echo "=================================================="

# Change to project directory
cd "$(dirname "$0")/src/BFB.AWSS3Light.Storage.S3.Standalone"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
dotnet clean --verbosity minimal

# Restore dependencies
echo "📦 Restoring NuGet packages..."
dotnet restore --verbosity minimal

# Build and pack
echo "🔨 Building and creating NuGet package..."
dotnet build --configuration Release --no-restore --verbosity minimal

echo "✅ Build completed successfully!"
echo ""

# List generated packages
cd ../../nupkg
echo "📋 Generated packages:"
ls -la *.nupkg *.snupkg 2>/dev/null | grep "BFB.AWSS3Light.Storage.S3" || echo "No packages found"

echo ""
echo "🎉 Package build complete!"
echo "   Package location: ./nupkg/"
echo "   Ready for distribution or local testing"