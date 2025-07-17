#!/bin/bash

# Create splash screen assets for FromFedToChain app
# This script converts the SVG icon to PNG format for native splash screens

echo "🎨 Creating splash screen assets..."

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick not found. Please install it:"
    echo "   macOS: brew install imagemagick"
    echo "   Ubuntu: sudo apt-get install imagemagick"
    echo "   Windows: Download from https://imagemagick.org/script/download.php"
    exit 1
fi

# Create assets directory if it doesn't exist
mkdir -p assets

# Convert SVG to PNG at different sizes
echo "📐 Converting SVG to PNG..."

# Main splash logo (1024x1024)
convert assets/fromfedtochain-icon.svg -resize 1024x1024 -background transparent assets/splash_logo.png

# Android adaptive icon (512x512)
convert assets/fromfedtochain-icon.svg -resize 512x512 -background transparent assets/adaptive_icon.png

# iOS app icon (1024x1024)
convert assets/fromfedtochain-icon.svg -resize 1024x1024 -background transparent assets/app_icon.png

echo "✅ Splash assets created successfully!"
echo "📁 Files created:"
echo "   - assets/splash_logo.png (1024x1024) - Main splash screen"
echo "   - assets/adaptive_icon.png (512x512) - Android adaptive icon"
echo "   - assets/app_icon.png (1024x1024) - iOS app icon"

echo ""
echo "🚀 Next steps:"
echo "1. Run: flutter pub get"
echo "2. Run: flutter pub run flutter_native_splash:create"
echo "3. Test the splash screen: flutter run"

echo ""
echo "📱 Platform-specific notes:"
echo "- Android: Splash screen will show on app launch"
echo "- iOS: Splash screen will show on app launch"
echo "- Web: Splash screen will show in browser"