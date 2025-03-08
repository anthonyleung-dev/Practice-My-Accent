#!/bin/bash

# This script assumes you have ImageMagick installed
# If not, install it with: brew install imagemagick (Mac) or apt-get install imagemagick (Linux)

# Convert webp to png if needed
convert asset.webp app_icon.png

# Create Android app icons in different sizes
mkdir -p temp_icons

# Generate icons for different densities
convert app_icon.png -resize 48x48 temp_icons/icon_mdpi.png
convert app_icon.png -resize 72x72 temp_icons/icon_hdpi.png
convert app_icon.png -resize 96x96 temp_icons/icon_xhdpi.png
convert app_icon.png -resize 144x144 temp_icons/icon_xxhdpi.png
convert app_icon.png -resize 192x192 temp_icons/icon_xxxhdpi.png

# Copy to appropriate Android directories
cp temp_icons/icon_mdpi.png android/app/src/main/res/mipmap-mdpi/ic_launcher.png
cp temp_icons/icon_hdpi.png android/app/src/main/res/mipmap-hdpi/ic_launcher.png
cp temp_icons/icon_xhdpi.png android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
cp temp_icons/icon_xxhdpi.png android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
cp temp_icons/icon_xxxhdpi.png android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

# Also copy for round icons (Android adaptive icons)
cp temp_icons/icon_mdpi.png android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png
cp temp_icons/icon_hdpi.png android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png
cp temp_icons/icon_xhdpi.png android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png
cp temp_icons/icon_xxhdpi.png android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png
cp temp_icons/icon_xxxhdpi.png android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png

# Clean up
rm -rf temp_icons

echo "Android app icons have been generated and placed in the appropriate directories." 