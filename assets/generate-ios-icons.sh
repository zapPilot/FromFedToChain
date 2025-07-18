#!/bin/bash

# Generate iOS app icons from app-icon.png

# Base source image
SOURCE="app-icon.png"
DEST_DIR="../ios/Runner/Assets.xcassets/AppIcon.appiconset"

# Create all required iOS icon sizes
echo "Generating iOS app icons..."

# 20x20 series
sips -z 20 20 "$SOURCE" --out temp.png && cp temp.png "$DEST_DIR/Icon-App-20x20@1x.png" && rm temp.png
sips -z 40 40 "$SOURCE" --out temp.png && cp temp.png "$DEST_DIR/Icon-App-20x20@2x.png" && rm temp.png
sips -z 60 60 "$SOURCE" --out temp.png && cp temp.png "$DEST_DIR/Icon-App-20x20@3x.png" && rm temp.png

# 29x29 series
sips -z 29 29 "$SOURCE" --out temp.png && cp temp.png "$DEST_DIR/Icon-App-29x29@1x.png" && rm temp.png
sips -z 58 58 "$SOURCE" --out temp.png && cp temp.png "$DEST_DIR/Icon-App-29x29@2x.png" && rm temp.png
sips -z 87 87 "$SOURCE" --out temp.png && cp temp.png "$DEST_DIR/Icon-App-29x29@3x.png" && rm temp.png

# 40x40 series
sips -z 40 40 "$SOURCE" --out temp.png && cp temp.png "$DEST_DIR/Icon-App-40x40@1x.png" && rm temp.png
sips -z 80 80 "$SOURCE" --out temp.png && cp temp.png "$DEST_DIR/Icon-App-40x40@2x.png" && rm temp.png
sips -z 120 120 "$SOURCE" --out temp.png && cp temp.png "$DEST_DIR/Icon-App-40x40@3x.png" && rm temp.png

# 60x60 series
sips -z 120 120 "$SOURCE" --out temp.png && cp temp.png "$DEST_DIR/Icon-App-60x60@2x.png" && rm temp.png
sips -z 180 180 "$SOURCE" --out temp.png && cp temp.png "$DEST_DIR/Icon-App-60x60@3x.png" && rm temp.png

# 76x76 series
sips -z 76 76 "$SOURCE" --out temp.png && cp temp.png "$DEST_DIR/Icon-App-76x76@1x.png" && rm temp.png
sips -z 152 152 "$SOURCE" --out temp.png && cp temp.png "$DEST_DIR/Icon-App-76x76@2x.png" && rm temp.png

# 83.5x83.5 series
sips -z 167 167 "$SOURCE" --out temp.png && cp temp.png "$DEST_DIR/Icon-App-83.5x83.5@2x.png" && rm temp.png

# 1024x1024 App Store icon
sips -z 1024 1024 "$SOURCE" --out temp.png && cp temp.png "$DEST_DIR/Icon-App-1024x1024@1x.png" && rm temp.png

echo "iOS app icons generated successfully!"