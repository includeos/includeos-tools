#!/bin/bash
# Script for creating a bootable mac OS sierra (or El Capitan) image from the installation app
# provided by Apple
# Download the official package to run this script
# Example esd path: /Applications/Install\ macOS\ Sierra.app/Contents/SharedSupport/InstallESD.dmg
# Commands taken from: http://anadoxin.org/blog/creating-a-bootable-el-capitan-iso-image.html
# Script outline taken from: http://www.insanelymac.com/forum/topic/293481-how-to-create-a-bootable-iso-from-the-mavericks-installesddmg/#entry1962575

ESD=$1

if [ -z "$ESD" ]; then
    echo usage: "'$0' /path/to/esd"
    exit 1
fi
if ! [ -e "$ESD" ]; then
    echo "file '$ESD' does not exist"
    exit 1
fi

MPAPP=/Volumes/install_app	# Installer image path
MPIMG=/Volumes/install_img	# New image path
MPBASE=/Volumes/OS\ X\ Base\ System	# Created by asr command
IMGNAME=install				# Image name

detach_all() {
  if [ -d "$MPAPP" ]; then hdiutil detach "$MPAPP"; fi
  if [ -d "$MPIMG" ]; then hdiutil detach "$MPIMG"; fi
  if [ -d "$MPBASE" ]; then hdiutil detach "$MPBASE"; fi
}
exit_all() {
  echo +++ Command returned with error, aborting ...
  rm $IMGNAME.*
  exit 2
}

trap detach_all EXIT
trap exit_all ERR

echo +++ Trying to unmount anything from previous run
detach_all


echo +++ Mount the installer image
hdiutil attach "$ESD" -noverify -nobrowse -mountpoint "$MPAPP"

echo +++ Create placeholder image of our ISO file
hdiutil create -o "$IMGNAME".cdr -size 7316m -layout SPUD -fs HFS+J

echo +++ Mount the placeholder image
hdiutil attach "$IMGNAME".cdr.dmg -noverify -nobrowse -mountpoint "$MPIMG"

echo +++ Populate the contents of the new drive
asr restore -source "$MPAPP"/BaseSystem.dmg -target "$MPIMG" -noprompt -noverify -erase

echo +++ Removed unused link
rm /Volumes/OS\ X\ Base\ System/System/Installation/Packages
rm "$MPBASE"/System/Installation/Packages

echo +++ Copy files 
cp -rp "$MPAPP"/Packages "$MPBASE"/System/Installation
cp -rp "$MPAPP"/BaseSystem.chunklist "$MPBASE"
cp -rp "$MPAPP"/BaseSystem.dmg "$MPBASE"

echo +++ detach volumes
hdiutil detach "$MPAPP"
hdiutil detach "$MPBASE"

echo +++ Convert the image to udto format
hdiutil convert "$IMGNAME".cdr.dmg -format UDTO -o "$IMGNAME".iso

echo +++ Delete old image
rm "$IMGNAME".cdr.dmg

echo +++ Rename image
mv "$IMGNAME".iso.cdr "$IMGNAME".iso

echo "Done"
echo "Find your DVD at '$IMGNAME'.iso"
