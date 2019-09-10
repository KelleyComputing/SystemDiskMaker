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



# NUMBER_OF_PARTITIONS is the number of partitions to create on disk.
# This should equal the number of system images that are being created + 1.
NUMBER_OF_PARTITIONS=0

OS_INSTALLERS=("Install Mac OS X Lion.app" "Install OS X Mountain Lion.app" "Install OS X Mavericks.app" "Install OS X Yosemite.app" "Install OS X El Capitan.app" "Install macOS Sierra.app" "Install macOS High Sierra.app" "Install macOS Mojave.app")

# PARTITION_FORMAT is the format that each partition will be intialized in.
# At this time, there is only 1 format that will be used (jhfs+), which is
# Journaled HFS+
PARTITION_FORMAT="jhfs+"


check_root() {
    if [ `whoami` != "root" ]; then
        echo "Error: insufficient permissions - this script must be executed as root!"
		usage
		exit 1
    fi
}


usage()
{
cat << EOF
usage: $0 [ -f ] [ -v ] [ -p /path/to/installers ] -d diskIdentifier

This script will create multiple bootable Mac OS X / macOS volumes on a single disk.
The script looks for installer images at the specified path (or in /Applications by default).

OPTIONS:
   -d      Whole disk identifier to create partitions on
   -f      Force (do not prompt for confirmation)
   -h      Show this message
   -p      Path to installer location containing installer images (default is /Applications)
   -v      Verbose

EXAMPLES:

    Create an installer disk on physical disk "disk1" using system installers found in the default location
	$0 -d disk1

    Create an installer on disk1 from installers at /Volumes/Storage/Applications (verbosely)
	$0 -v -d disk1 -p /Volumes/Storage/Applications
EOF
}


find_systems()
{
	i=0
	for INSTALLER in "${OS_INSTALLERS[@]}"; do
		if [ ! -z "$VERBOSE" ]; then
			echo "Checking for system at path $OS_INSTALLER_BASE_PATH/$INSTALLER..."
		fi
		if [ ! -d "$OS_INSTALLER_BASE_PATH/$INSTALLER" ]; then
			# if the installer doesn't exist, remove it from the OS_INSTALLERS array
			unset OS_INSTALLERS[i]
		else
		 	if [ ! -z "$VERBOSE" ]; then
				echo "Found OS installer at path: $OS_INSTALLER_BASE_PATH/$INSTALLER."
			fi
			NUMBER_OF_PARTITIONS=$(( $NUMBER_OF_PARTITIONS + 1))
		fi
		i=$(( $i + 1 ))
	done
	if [ ! -z "$VERBOSE" ]; then
		echo "Found $NUMBER_OF_PARTITIONS OS installers: ${OS_INSTALLERS[@]}"
	fi
}

restore_lion_disk()
{
	if [ ! -z "$VERBOSE" ]; then
		asr --source "$1/Contents/SharedSupport/InstallESD.dmg" --target "$2" --erase --noprompt
	else
		asr --source "$1/Contents/SharedSupport/InstallESD.dmg" --target "$2" --erase --noprompt > /dev/null 2>&1
	fi
}

restore_disk()
{
	if [ ! -z "$VERBOSE" ]; then
		"$1/Contents/Resources/createinstallmedia" --applicationpath "$1" --volume "$2" --nointeraction
	else
		"$1/Contents/Resources/createinstallmedia" --applicationpath "$1" --volume "$2" --nointeraction > /dev/null 2>&1
	fi
}

make_disk()
{
	# Each partition name must be specified when created. For safety, we are
	# using random UUID values, which will help to avoid name collisions.
	PARTITION_NAMES=()
	for i in $(seq 0 $(( $NUMBER_OF_PARTITIONS - 1))); do
		PARTITION_NAMES[$i]=`uuidgen`
	done

	# STORAGE_PARTITION_NAME is the name of the last partition of the disk
	STORAGE_PARTITION_NAME="Storage"

	# Each partition must have a size specified - 10GB is sufficient for each
	# system partition. One additional "Storage" partition will round out the
	# remaining storage on the disk (specified by the "R" diskutil SIZES value)
	PARTITION_SIZE="10G"
	STORAGE_PARTITION_SIZE="R"

	# Create N partitions where N is the number of system images
	# to be imaged/created on this disk
	DISKUTIL_COMMAND="diskutil"
	if [ -z "$VERBOSE" ]; then
		DISKUTIL_COMMAND="${DISKUTIL_COMMAND} quiet"
	fi
	DISKUTIL_COMMAND="${DISKUTIL_COMMAND} partitionDisk /dev/$DISK $(( $NUMBER_OF_PARTITIONS + 1 )) GPTFormat"
	for PARTITION_NAME in "${PARTITION_NAMES[@]}"; do
		DISKUTIL_COMMAND="${DISKUTIL_COMMAND} $PARTITION_FORMAT $PARTITION_NAME $PARTITION_SIZE"
	done
	DISKUTIL_COMMAND="${DISKUTIL_COMMAND} $PARTITION_FORMAT $STORAGE_PARTITION_NAME $STORAGE_PARTITION_SIZE"

	if [ ! -z "$VERBOSE" ]; then
		echo "Running diskutil command: '$DISKUTIL_COMMAND' ..."
		$DISKUTIL_COMMAND
	else
		$DISKUTIL_COMMAND > /dev/null 2>&1
	fi

	# Image each partition with a system. Most will use the newer "createinstallmedia" command, but
	# older systems (such as Lion and Mountain Lion) will use asr to image the "InstallESD.dmg" file
	# to the chosen partition
	i=0
	for INSTALLER in "${OS_INSTALLERS[@]}"; do
		case $INSTALLER in
			"Install Mac OS X Lion.app" | "Install OS X Mountain Lion.app")
				restore_lion_disk "$OS_INSTALLER_BASE_PATH/$INSTALLER" "/Volumes/${PARTITION_NAMES[$i]}"
				;;
			"Install OS X Mavericks.app" | "Install OS X Yosemite.app" | "Install OS X El Capitan.app" | "Install macOS Sierra.app" | "Install macOS High Sierra.app" | "Install macOS Mojave.app")
				restore_disk "$OS_INSTALLER_BASE_PATH/$INSTALLER" "/Volumes/${PARTITION_NAMES[$i]}"
				;;
			*)
				echo "Error: unrecognized installer: $INSTALLER"
				exit 1
				;;
		esac
		i=$(( $i + 1 ))
	done
}


while getopts  "d:fhp:v" flag
do
	if [ "$flag" == "h" ]; then
		usage
		exit
	elif [ "$flag" == "p" ]; then
		OS_INSTALLER_BASE_PATH="$OPTARG"
	elif [ "$flag" == "f" ]; then
		FORCE="YES"
	elif [ "$flag" == "v" ]; then
		VERBOSE="YES"
	elif [ "$flag" == "d" ]; then
		if [ -z "$flag" ]; then
			echo "Error: option:$flag requires an argument"
			usage
			exit 1
		else
			DISK="$OPTARG"
		fi
	elif [ "$flag" == "?" ]; then
		usage
		exit
	fi
done


# verify that the script is being executed with privileges
check_root

# verify that a disk argument is being provided
if [ -z "$DISK" ]; then
	echo "Error: it is necessary to specify a whole disk (e.g., \"disk2\") using the '-d' argument!"
	usage
	exit 1
fi

# verify that the OS_INSTALLER_BASE_PATH actually exists
if [ -z "$OS_INSTALLER_BASE_PATH" ]; then
	# OS_INSTALLER_BASE_PATH is the location that the installation applications are
	# stored. For example "/Applications", "/Volumes/Storage/OS Installers", etc.
	#
	OS_INSTALLER_BASE_PATH="/Applications"
fi

find_systems

make_disk
