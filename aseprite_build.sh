#!/bin/bash

# # this is for tools required 
# brew update
# brew install ninja
# brew install cmake

# crete the default root directory
export PWD=$(pwd)

mkdir deps

# download skia m102
curl -L "https://github.com/aseprite/skia/releases/download/m102-861e4743af/Skia-macOS-Release-arm64.zip" -o deps/Skia-macOS-Release-arm64.zip
unzip deps/Skia-macOS-Release-arm64.zip -d deps/skia-m102

# this is the project itselft
git clone --recursive https://github.com/aseprite/aseprite.git

# compiling aseprite
cd aseprite
mkdir build
cd build
cmake \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=13.3 \
  -DCMAKE_OSX_SYSROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk \
  -DUSE_ALLEG4_BACKEND=OFF \
  -DUSE_SKIA_BACKEND=ON \
  -DSKIA_DIR=../../deps/skia-m102 \
  -DSKIA_LIBRARY_DIR=../../deps/skia-m102/out/Release-arm64 \
  -DSKIA_LIBRARY=../../deps/skia-m102/out/Release-arm64/libskia.a \
  -DPNG_ARM_NEON:STRING=on \
  -G Ninja \
  ..

ninja aseprite
cd ../..


# BUNDLE
export PROJECT=Aseprite
export BUNDLE=$PROJECT.app
export BUNDLE_DIR=/Applications/$BUNDLE
export ICNS_APP=appicon.icns
export ICNS_FILES=filesicon.icns
export PLIST=Info.plist

mkdir $BUNDLE_DIR
mkdir -p $BUNDLE_DIR/Contents/MacOS/
mkdir -p $BUNDLE_DIR/Contents/Resources/
cp -r aseprite/build/bin/aseprite $BUNDLE_DIR/Contents/MacOS/aseprite
cp -r aseprite/build/bin/data $BUNDLE_DIR/Contents/Resources/data
#cp Info.plist $BUNDLE_DIR/Contents/Info.plist
sed "s/PROJECT/${PROJECT}/" $PLIST > deps/$PLIST.temp1
sed "s/ICNS_APP/${ICNS_APP}/" deps/$PLIST.temp1 > deps/$PLIST.temp2
rm deps/$PLIST.temp1
sed "s/ICNS_FILES/${ICNS_FILES}/" deps/$PLIST.temp2 > deps/$PLIST.temp3
rm deps/$PLIST.temp2
mv deps/$PLIST.temp3 $BUNDLE_DIR/Contents/Info.plist

# create icon (https://stackoverflow.com/questions/646671/how-do-i-set-the-icon-for-my-applications-mac-os-x-app-bundle)
export ORIGICON=aseprite/data/icons/

mkdir -p deps/$ICNS_APP.iconset

# Normal screen icons
for SIZE in 16 32 64 128 256; do
cp $ORIGICON/ase${SIZE}.png deps/$ICNS_APP.iconset/icon_${SIZE}x${SIZE}.png ;
done

for SIZE in 32 64 128 256; do
cp $ORIGICON/ase${SIZE}.png deps/$ICNS_APP.iconset/icon_$(expr $SIZE / 2)x$(expr $SIZE / 2)x2.png ;
done

# Make a multi-resolution Icon
iconutil -c icns -o deps/$PROJECT.icns deps/$ICNS_APP.iconset
rm -rf deps/$ICNS_APP.iconset #it is useless now
cp deps/$PROJECT.icns $BUNDLE_DIR/Contents/Resources/$ICNS_APP

mkdir -p deps/$ICNS_FILES.iconset

# Normal screen icons
for SIZE in 16 32 64 128 256; do
cp $ORIGICON/doc${SIZE}.png deps/$ICNS_FILES.iconset/icon_${SIZE}x${SIZE}.png ;
done

for SIZE in 32 64 128 256; do
cp $ORIGICON/doc${SIZE}.png deps/$ICNS_FILES.iconset/icon_$(expr $SIZE / 2)x$(expr $SIZE / 2)x2.png ;
done

# Make a multi-resolution Icon
iconutil -c icns -o deps/$PROJECT.icns deps/$ICNS_FILES.iconset
rm -rf deps/$ICNS_FILES.iconset #it is useless now
cp deps/$PROJECT.icns $BUNDLE_DIR/Contents/Resources/$ICNS_FILES

echo "\ndone\!"
