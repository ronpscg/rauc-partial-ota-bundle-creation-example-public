#!/bin/bash
#
# This is an example of a rauc hook to be packed in a bundle. It illustrates, for each slot:
# 1. Unpacking a tarball for the slot onto the standby slot (target slot) file system
# 2. Executing a "setup-instructions.sh" , if such exists in the tarball
#
echo -e "\e[32m$0 called with $@ \e[35m;\ntarget device: $RAUC_SLOT_DEVICE ;\ntarget image tarball: $RAUC_IMAGE_NAME \e[0m"

case "$1" in
	slot-install)
		TARGET_DEV="$RAUC_SLOT_DEVICE"
		MOUNT_POINT="/tmp/rauc-install-mount"
		PAYLOAD="$RAUC_IMAGE_NAME"

		echo "--- Starting Custom Install Hook ---"
		#
		# --- Robust Active Partition Check ---
		#
		# Get the major/minor device ID of the current root filesystem
		ROOT_DEV_ID=$(stat -c "%d" /)

		# Get the major/minor device ID of the target device node
		TARGET_DEV_ID=$(stat -L -c "%t%T" "$TARGET_DEV")
		# Convert hex to decimal to match 'stat -c %d' format
		TARGET_DEV_DEC=$((0x${TARGET_DEV_ID%??} * 256 + 0x${TARGET_DEV_ID#??}))

		if [ "$ROOT_DEV_ID" -eq "$TARGET_DEV_DEC" ]; then
			echo "FATAL: Target $TARGET_DEV is the ACTIVE partition (ID: $ROOT_DEV_ID)!"
			exit 1
		fi

		#
		# --- Setup and mount ---
		#
		mkdir -p "$MOUNT_POINT"
		if grep -qs "$MOUNT_POINT" /proc/mounts; then
			umount -l "$MOUNT_POINT"
		fi

		echo "Mounting $TARGET_DEV to $MOUNT_POINT..."
		mount "$TARGET_DEV" "$MOUNT_POINT" || exit 1

		#
		# --- Extraction ---
		#
		echo "Extracting $(basename "$PAYLOAD")..."
		tar -xf "$PAYLOAD" -C "$MOUNT_POINT"
		if [ $? -ne 0 ]; then
			echo "Error: Extraction failed!"
			umount "$MOUNT_POINT"
			exit 1
		else
			echo -e "\x1b[44mEXTRACTED TARBALL into $MOUNT_POINT\x1b[0m"
			echo ------------------------
			echo "$MOUNT_POINT contents:"
			echo ------------------------
			ls $MOUNT_POINT
			echo ------------------------
			echo "Tarball contents:"
			echo ------------------------
			tar tf $PAYLOAD
			echo -e "\x1b[44mdoneEXTRACTED TARBALL into $MOUNT_POINT\x1b[0m"
		fi
	
	#
	# --- Run setup-instructions.sh ---
	#
	SETUP_SCRIPT="$MOUNT_POINT/setup-instructions.sh"
	if [ -f "$SETUP_SCRIPT" ]; then
		echo -e "\x1b[43mExecuting setup script...\x1b[0m"
		chmod +x "$SETUP_SCRIPT"
		"$SETUP_SCRIPT" "$MOUNT_POINT"
		RESULT=$?
		[ $RESULT -eq 0 ] && rm "$SETUP_SCRIPT" || { umount "$MOUNT_POINT"; exit 1; }
	fi

	umount "$MOUNT_POINT"
	echo -e "\x1b[32m--- Success ---\x1b[0m"
	exit 0
	;;
*)
	exit 0
	;;
esac
