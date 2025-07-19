#!/bin/bash

# Generate Android app icons from app-icon.png

# Base source image
SOURCE="app-icon.png"
ANDROID_RES="../android/app/src/main/res"

# Create all required Android icon sizes
echo "Generating Android app icons..."

# mdpi (48x48)
sips -z 48 48 "$SOURCE" --out temp.png && cp temp.png "$ANDROID_RES/mipmap-mdpi/ic_launcher.png" && rm temp.png

# hdpi (72x72)
sips -z 72 72 "$SOURCE" --out temp.png && cp temp.png "$ANDROID_RES/mipmap-hdpi/ic_launcher.png" && rm temp.png

# xhdpi (96x96)
sips -z 96 96 "$SOURCE" --out temp.png && cp temp.png "$ANDROID_RES/mipmap-xhdpi/ic_launcher.png" && rm temp.png

# xxhdpi (144x144)
sips -z 144 144 "$SOURCE" --out temp.png && cp temp.png "$ANDROID_RES/mipmap-xxhdpi/ic_launcher.png" && rm temp.png

# xxxhdpi (192x192)
sips -z 192 192 "$SOURCE" --out temp.png && cp temp.png "$ANDROID_RES/mipmap-xxxhdpi/ic_launcher.png" && rm temp.png

echo "Android app icons generated successfully!"