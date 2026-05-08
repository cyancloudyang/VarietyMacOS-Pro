#!/bin/bash
# VarietyMacOS Core Logic Test Script

cd /Users/cycloudyang/VarietyMacOS

echo "=== VarietyMacOS Core Logic Tests ==="
echo ""

# Test 1: Check project structure
echo "Test 1: Checking project structure..."
if [ -f "VarietyMacOS.xcodeproj/project.pbxproj" ]; then
    echo "✓ Project file exists"
else
    echo "✗ Project file missing"
    exit 1
fi

# Test 2: Check required source files
echo ""
echo "Test 2: Checking source files..."
required_files=(
    "VarietyMacOS/VarietyMacOSApp.swift"
    "VarietyMacOS/Core/WallpaperManager.swift"
    "VarietyMacOS/Core/ScreenManager.swift"
    "VarietyMacOS/Preferences/Preferences.swift"
    "VarietyMacOS/Sources/WallpaperSource.swift"
    "VarietyMacOS/Utilities/DownloadError.swift"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file missing"
    fi
done

# Test 3: Build test
echo ""
echo "Test 3: Building project..."
if xcodebuild -scheme VarietyMacOS -destination 'platform=macOS' build 2>&1 | grep -q "BUILD SUCCEEDED"; then
    echo "✓ Build succeeded"
else
    echo "✗ Build failed"
fi

# Test 4: Check DownloadError enum
echo ""
echo "Test 4: Checking DownloadError enum..."
if grep -q "enum DownloadError" VarietyMacOS/Utilities/DownloadError.swift; then
    echo "✓ DownloadError enum found"
else
    echo "✗ DownloadError enum missing"
fi

# Test 5: Check for @MainActor issues
echo ""
echo "Test 5: Checking for @MainActor annotations..."
main_actor_count=$(grep -r "@MainActor" VarietyMacOS/ 2>/dev/null | wc -l)
echo "Found $main_actor_count @MainActor annotations"

# Test 6: Check ScreenSelectionView fix
echo ""
echo "Test 6: Checking ScreenSelectionView fix..."
if grep -q "@ObservedObject" VarietyMacOS/App/MenuBarView.swift; then
    echo "✓ ScreenSelectionView uses @ObservedObject"
else
    echo "✗ ScreenSelectionView fix not found"
fi

echo ""
echo "=== All Tests Completed ==="
