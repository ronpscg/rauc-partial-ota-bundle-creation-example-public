#!/bin/bash

# 
# This file helps to quickly do modifications in a partial rootfs update, and test the mechanism.
#
# The objective of this file is to:
# * (re)populate the rauc/ folder which already has a rauc manifest [and a tarball for the boot partition] with a rootfs generated from setup instructions and some files/folders
# * build the bundle
# * copy the bundle to the root user's home directory on the target
#
# The user can then install the bundle on the target (can also do it with an ssh command) by doing
# # rauc install bundle.raucb
# And test by rebooting the machine and observing the new rootfs (and/or boot if one packed significant boot files)
#


setup_by_local_config() {
	rc=0
	if [ ! -e local.config ] ; then
		echo "Please provide a local.config file according to the instructions in the REAMDE.md file of this project"
		exit 1
	fi
	. ./local.config || exit 1
	if [ -z "$RAUC_COMPATIBLE" -o -z "$SSH_USER_AT_HOST" ] ; then
		echo "Please populate the local.config properly"
		exit 1
	fi

	if [ ! -f rauc/manifest.raucm ] ; then
		echo "[+] Populating your rauc manifest for the first time"
		cat > rauc/manifest.raucm << EOF
#
# A template for partial tarball based update
# You have been warned it requires considerable deisgn, execution, trade-offs, mindfulness of your devices, for all eternities, be warned again!
# (on the other hand: things will be considerably faster and lower on network bandwidth if you craft your updates carefully - it doesn't mean I recommend it!)
#
#
[update]
compatible=$RAUC_COMPATIBLE
version=2026.03.19-partial

[hooks]
filename=hooks.sh

[image.rootfs]
filename=rootfs_partial_payload.tar.gz
hooks=install

[image.boot]
filename=boot_partial_payload.tar.gz
hooks=install

EOF
	fi
}

#
# The objective here is to do the following:
# - If keys/ exist - use it as is and return
# - Otherwise - if $TARGET_KEYS_DIR exists (e.g. the one in site.conf, or otherwise used in the Yocto Project (or other build system) directory - copy the relevant ones into keys/ and use it
# - Else if none exits - be generous and kind, create the keys in keys, and copy them over to the TARGET_DIR
# 
create_keys_or_reuse_if_necessary() {
	export TARGET_KEYS_DIR ORG CA CRL KEY_GENERATION_WORKDIR
	if [ -f $KEYRING -a -f $PUBLIC_KEY_CERT -a -f $PRIVATE_KEY ] ; then
		return
	elif [ ! -d $TARGET_KEYS_DIR ] ; then
		cd $KEY_GENERATION_SCRIPTS_DIR
		./create-rauc-keys-dev.sh
		cd - > /dev/null
	fi
	if ! cp $TARGET_KEYS_DIR/* $BUNDLE_KEYS_DIR ; then
		echo "$TARGET_KEYS_DIR did not contain keys."
		exit 1
	fi
}

create_and_copy_bundle_to_target() {
	echo "[+] Updating boot partial patch..."
	cp example-update-contents/boot_partial_payload.tar.gz rauc/
	echo "[+] Updating rootfs partial patch..."
	tar -C example-update-contents -czf rauc/rootfs_partial_payload.tar.gz debs/  setup-instructions.sh
	echo "[+] Creating bundle..."
	rm -f ${BUNDLE_NAME}
	rauc bundle \
		--keyring=${KEYRING} \
		--cert=${PUBLIC_KEY_CERT} \
		--key=${PRIVATE_KEY} \
		${DIR_NAME} \
		${BUNDLE_NAME}
			echo "[+] Copying to target..."
			scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${BUNDLE_NAME} ${SSH_USER_AT_HOST}:
}

init_vars() {
	# Variables directly used by this script
	: ${DIR_NAME=rauc}
	: ${BUNDLE_NAME=bundle.raucb}
	: ${BUNDLE_KEYS_DIR=$LOCAL_DIR/keys}
	: ${KEYRING=$BUNDLE_KEYS_DIR/ca.cert.pem}
	: ${PUBLIC_KEY_CERT=$BUNDLE_KEYS_DIR/development-1.cert.pem}
	: ${PRIVATE_KEY=$BUNDLE_KEYS_DIR/development-1.key.pem}

	# Variables used for the generation of keys materials, if necessary
	: ${KEY_GENERATION_SCRIPTS_DIR=$LOCAL_DIR/create-keys-scripts}
	: ${TARGET_KEYS_DIR=$HOME/pscg/customers/build-stuff/rauc/keys1}
	: ${KEY_GENERATION_WORKDIR=$BUNDLE_KEYS_DIR/example-workdir}
	# You would likely want to change the CA related variables to your own values
	: ${ORG="The PSCG"}
	: ${CA="Example CA"}
	: ${CRL="-crldays 5000"}	# After 5000 days in this example - you won't be able to sign and verify keys!
}

main() {
	LOCAL_DIR=$(readlink -f $(dirname ${BASH_SOURCE[0]}))
	cd $LOCAL_DIR
	init_vars
	create_keys_or_reuse_if_necessary
	setup_by_local_config
	create_and_copy_bundle_to_target
}
main $@
