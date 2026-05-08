#!/bin/bash
# Test script to help diagnose the deadlock issue

echo "=== Testing WallpaperManager Concurrency ==="
echo ""
echo "Steps to reproduce the issue:"
echo "1. Click 'Fetch' button - should work quickly"
echo "2. Click 'Next' button - shows 'Fetching...' forever"
echo "3. Click 'Next' again - app freezes"
echo ""
echo "What to look for in the console output:"
echo "- Check if 'isLoading set to false' is printed after fetch completes"
echo "- Check if the second call sees 'isLoading=true' and returns immediately"
echo "- Check if any async operations are blocking"
echo ""
echo "Please run the app and watch the console output."
echo "The fix should show proper state reset in all cases."
