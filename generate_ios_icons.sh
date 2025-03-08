#!/bin/bash

# This script assumes you have ImageMagick installed
# If not, install it with: brew install imagemagick (Mac) or apt-get install imagemagick (Linux)

# Convert webp to png if needed

# Create iOS app icons in different sizes
mkdir -p temp_icons

# Generate icons for different iOS sizes
convert app_icon.png -resize 20x20 temp_icons/Icon-20x20@1x.png
convert app_icon.png -resize 40x40 temp_icons/Icon-20x20@2x.png
convert app_icon.png -resize 60x60 temp_icons/Icon-20x20@3x.png
convert app_icon.png -resize 29x29 temp_icons/Icon-29x29@1x.png
convert app_icon.png -resize 58x58 temp_icons/Icon-29x29@2x.png
convert app_icon.png -resize 87x87 temp_icons/Icon-29x29@3x.png
convert app_icon.png -resize 40x40 temp_icons/Icon-40x40@1x.png
convert app_icon.png -resize 80x80 temp_icons/Icon-40x40@2x.png
convert app_icon.png -resize 120x120 temp_icons/Icon-40x40@3x.png
convert app_icon.png -resize 120x120 temp_icons/Icon-60x60@2x.png
convert app_icon.png -resize 180x180 temp_icons/Icon-60x60@3x.png
convert app_icon.png -resize 76x76 temp_icons/Icon-76x76@1x.png
convert app_icon.png -resize 152x152 temp_icons/Icon-76x76@2x.png
convert app_icon.png -resize 167x167 temp_icons/Icon-83.5x83.5@2x.png
convert app_icon.png -resize 1024x1024 temp_icons/Icon-1024x1024@1x.png

# Copy to iOS AppIcon.appiconset directory
cp temp_icons/*.png ios/Runner/Assets.xcassets/AppIcon.appiconset/

# Update the Contents.json file
cat > ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json << 'EOL'
{
  "images" : [
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "Icon-20x20@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "20x20",
      "idiom" : "iphone",
      "filename" : "Icon-20x20@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-29x29@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-29x29@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "iphone",
      "filename" : "Icon-29x29@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "Icon-40x40@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "iphone",
      "filename" : "Icon-40x40@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "Icon-60x60@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "60x60",
      "idiom" : "iphone",
      "filename" : "Icon-60x60@3x.png",
      "scale" : "3x"
    },
    {
      "size" : "20x20",
      "idiom" : "ipad",
      "filename" : "Icon-20x20@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "20x20",
      "idiom" : "ipad",
      "filename" : "Icon-20x20@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "29x29",
      "idiom" : "ipad",
      "filename" : "Icon-29x29@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "29x29",
      "idiom" : "ipad",
      "filename" : "Icon-29x29@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "40x40",
      "idiom" : "ipad",
      "filename" : "Icon-40x40@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "40x40",
      "idiom" : "ipad",
      "filename" : "Icon-40x40@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "76x76",
      "idiom" : "ipad",
      "filename" : "Icon-76x76@1x.png",
      "scale" : "1x"
    },
    {
      "size" : "76x76",
      "idiom" : "ipad",
      "filename" : "Icon-76x76@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "83.5x83.5",
      "idiom" : "ipad",
      "filename" : "Icon-83.5x83.5@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "1024x1024",
      "idiom" : "ios-marketing",
      "filename" : "Icon-1024x1024@1x.png",
      "scale" : "1x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOL

# Clean up
rm -rf temp_icons

echo "iOS app icons have been generated and placed in the appropriate directory." 