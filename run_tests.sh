#!/bin/bash
# Test Runner Script for VarietyMacOS
# This script helps run tests for the VarietyMacOS project

set -e

PROJECT_DIR="/Users/cycloudyang/VarietyMacOS"
PROJECT_NAME="VarietyMacOS"
SCHEME="VarietyMacOS"

echo "=== VarietyMacOS Test Runner ==="
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "Error: xcodebuild not found. Please install Xcode."
    exit 1
fi

# Navigate to project directory
cd "$PROJECT_DIR"

echo "Project: $PROJECT_NAME"
echo "Scheme: $SCHEME"
echo ""

# List available schemes
echo "Available schemes:"
xcodebuild -list -project "$PROJECT_NAME.xcodeproj" | grep -A 100 "Schemes:" | head -20
echo ""

# Run tests
echo "Running tests..."
echo ""

xcodebuild test \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -destination 'platform=macOS' \
    -enableCodeCoverage YES \
    2>&1 | tee test_output.log

echo ""
echo "=== Test Summary ==="
if grep -q "Test Suite.*passed" test_output.log; then
    echo "✅ Tests passed!"
    grep "Test Suite.*passed" test_output.log | tail -5
else
    echo "❌ Tests failed or could not run"
    grep -E "(error:|failed|Failed)" test_output.log | tail -10
fi

echo ""
echo "Full test log: test_output.log"
