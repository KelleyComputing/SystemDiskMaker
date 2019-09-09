#!/bin/bash
#
#    SystemDiskMaker automates the creation of multiple bootable Mac OS X / macOS volumes on a single disk
#    Copyright (C) 2019  Kelley Computing
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.


# Disk argument is passed in as $1 - e.g., "disk2"
DISK="$1"

if [ -z "$DISK" ]; then
	echo "Error: it is necessary to specify a whole disk (e.g., \"disk2\" as the first program argument!"
	exit 1
fi

OS_INSTALLER_BASE_PATH="$2"

if [ -z "$OS_INSTALLER_BASE_PATH" ]; then
	# OS_INSTALLER_BASE_PATH is the location that the installation applications are
	# stored. For example "/Applications", "/Volumes/Storage/OS Installers", etc.
	#
	OS_INSTALLER_BASE_PATH="/Applications"
fi

# NUMBER_OF_PARTITIONS is the number of partitions to create on disk.
# This should equal the number of system images that are being created + 1.
NUMBER_OF_PARTITIONS=9

# PARTITION_FORMAT is the format that each partition will be intialized in.
# At this time, there is only 1 format that will be used (jhfs+), which is
# Journaled HFS+
PARTITION_FORMAT="jhfs+"

# Each partition name must be specified when created. For safety, we are
# using random UUID values, which will help to avoid name collisions.
PARTITION1_NAME=`uuidgen`
PARTITION2_NAME=`uuidgen`
PARTITION3_NAME=`uuidgen`
PARTITION4_NAME=`uuidgen`
PARTITION5_NAME=`uuidgen`
PARTITION6_NAME=`uuidgen`
PARTITION7_NAME=`uuidgen`
PARTITION8_NAME=`uuidgen`
STORAGE_PARTITION_NAME="Storage"

# Each partition must have a size specified - 10GB is sufficient for each
# system partition. One additional "Storage" partition will round out the
# remaining storage on the disk (specified by the "R" diskutil SIZES value)
PARTITION_SIZE="10G"
STORAGE_PARTITION_SIZE="R"

# Create N partitions where N is the number of system images
# to be imaged/created on this disk

diskutil partitionDisk "/dev/$DISK" "$NUMBER_OF_PARTITIONS" GPTFormat \
"$PARTITION_FORMAT" "$PARTITION1_NAME" "$PARTITION_SIZE" \
"$PARTITION_FORMAT" "$PARTITION2_NAME" "$PARTITION_SIZE" \
"$PARTITION_FORMAT" "$PARTITION3_NAME" "$PARTITION_SIZE" \
"$PARTITION_FORMAT" "$PARTITION4_NAME" "$PARTITION_SIZE" \
"$PARTITION_FORMAT" "$PARTITION5_NAME" "$PARTITION_SIZE" \
"$PARTITION_FORMAT" "$PARTITION6_NAME" "$PARTITION_SIZE" \
"$PARTITION_FORMAT" "$PARTITION7_NAME" "$PARTITION_SIZE" \
"$PARTITION_FORMAT" "$PARTITION8_NAME" "$PARTITION_SIZE" \
"$PARTITION_FORMAT" "$STORAGE_PARTITION_NAME" "$STORAGE_PARTITION_SIZE"

# Image each partition with a system. Most will use the newer "createinstallmedia" command, but
# older systems (such as Lion and Mountain Lion) will use asr to image the "InstallESD.dmg" file
# to the chosen partition

# Mac OS X v.10.7 ("Lion")
asr --source "$OS_INSTALLER_BASE_PATH/Install Mac OS X Lion.app/Contents/SharedSupport/InstallESD.dmg" --target "/Volumes/$PARTITION1_NAME" --erase --noprompt

# OS X v.10.8 ("Mountain Lion")
asr --source "$OS_INSTALLER_BASE_PATH/Install OS X Mountain Lion.app/Contents/SharedSupport/InstallESD.dmg" --target "/Volumes/$PARTITION2_NAME" --erase --noprompt

# OS X v.10.9 ("Mavericks")
"$OS_INSTALLER_BASE_PATH/Install OS X Mavericks.app/Contents/Resources/createinstallmedia" --applicationpath "$OS_INSTALLER_BASE_PATH/Install OS X Mavericks.app" --volume "/Volumes/$PARTITION3_NAME" --nointeraction

# OS X v.10.10 ("Yosemite")
"$OS_INSTALLER_BASE_PATH/Install OS X Yosemite.app/Contents/Resources/createinstallmedia" --applicationpath "$OS_INSTALLER_BASE_PATH/Install OS X Yosemite.app" --volume "/Volumes/$PARTITION4_NAME" --nointeraction

# OS X v.10.11 ("El Capitan")
"$OS_INSTALLER_BASE_PATH/Install OS X El Capitan.app/Contents/Resources/createinstallmedia" --applicationpath "$OS_INSTALLER_BASE_PATH/Install OS X El Capitan.app" --volume "/Volumes/$PARTITION5_NAME" --nointeraction

# macOS v.10.12 ("Sierra")
"$OS_INSTALLER_BASE_PATH/Install macOS Sierra.app/Contents/Resources/createinstallmedia" --applicationpath "$OS_INSTALLER_BASE_PATH/Install macOS Sierra.app" --volume "/Volumes/$PARTITION6_NAME" --nointeraction

# macOS v.10.13 ("High Sierra")
"$OS_INSTALLER_BASE_PATH/Install macOS High Sierra.app/Contents/Resources/createinstallmedia" --applicationpath "$OS_INSTALLER_BASE_PATH/Install macOS High Sierra.app" --volume "/Volumes/$PARTITION7_NAME" --nointeraction

# macOS v.10.14 ("Mojave")
"$OS_INSTALLER_BASE_PATH/Install macOS Mojave.app/Contents/Resources/createinstallmedia" --applicationpath "$OS_INSTALLER_BASE_PATH/Install macOS Mojave.app" --volume "/Volumes/$PARTITION8_NAME" --nointeraction
