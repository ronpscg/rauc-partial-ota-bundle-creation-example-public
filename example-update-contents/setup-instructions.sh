#/bin/sh

#
# This script is run in the mounted target rootfs partition
#

fail_test_0() {
	bladglkajdlkgjdag # do something stupid and fail
}

fail_test_1() {
	   chroot . sh -c "dpkg -i python3-asyncio_3.12.4-r0_arm64.deb"
}

debug() { echo -e "SCRDBG: \x1b[44m$@\x1b[0m" ; }
info() { echo -e "SCRINF: \x1b[42m$@\x1b[0m" ; }

#
# $1 - place where the tarball was extracted
#
install_debian_packages() {
	ROOTDIR=$1
	DEBFOLDER=/debs
	echo "[+] Installing Debian packages from $DEBFOLDER"
	echo $PWD
	#echo "$0"
	#mount
	#ls $PWD
	debug "Listing $PWD\n------------"
	ls /
	debug "Listing mounts\n----------"
	mount

	echo "================== Will chroot =================="
	chroot $ROOTDIR sh -c "\
		debug() { echo -e \"\x1b[34m\$@\x1b[0m\" ; }  ; \
		info() { echo -e \"\x1b[32m\$@\x1b[0m\" ; }  ; \
		set -euo pipefail
		cd $DEBFOLDER && \
		debug Will dpkg now the contents of $DEBFOLDER && \
		dpkg -i python3-numbers_3.12.4-r0_arm64.deb && \
		dpkg -i python3-netclient_3.12.4-r0_arm64.deb && \
		dpkg -i python3-threading_3.12.4-r0_arm64.deb && \
		dpkg -i python3-html_3.12.4-r0_arm64.deb && \
		dpkg -i python3-netserver_3.12.4-r0_arm64.deb && \
		dpkg -i python3-pickle_3.12.4-r0_arm64.deb && \
		dpkg -i python3-logging_3.12.4-r0_arm64.deb && \
		dpkg -i python3-asyncio_3.12.4-r0_arm64.deb && \
		info DONE running chroot cmd
	"
	echo "================== After chroot =================="
}

main_logic() (
	set -euo pipefail # running in subshell - any failure here will report to the calling function so we can save ourselves some checks
	install_debian_packages $@
)

main() {
	info "$0 called with $@"

	main_logic $@
	rc=$?

	if [ "$rc" = "0" ] ; then
		echo -e "\x1b[32m$0 succeeded!\x1b[0m"
	else
		echo -e "\x1b[31m$0 failed!\x1b[0m"
	fi

	exit $rc
}
main $@
