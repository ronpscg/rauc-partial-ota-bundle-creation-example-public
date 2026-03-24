#!/bin/bash
#
# Created and adopted from the retired create-example-keys.sh
# Ron Munitz 2025
#

init_env() {
	: ${ORG="The PSCG"}
	: ${CA="Example CA"}

	# After the CRL expires, signatures cannot be verified anymore
	: ${CRL="-crldays 5000"}
	: ${KEY_GENERATION_WORKDIR=keys/example}

	BASE="$KEY_GENERATION_WORKDIR/example-ca"

	if [ -e $BASE ]; then
		echo "$BASE already exists"
		exit 1
	fi
}

create_pki() { 
	mkdir -p $BASE/{private,certs}
	touch $BASE/index.txt
	echo 01 > $BASE/serial

	cat > $BASE/openssl.cnf <<EOF
[ ca ]
default_ca      = CA_default               # The default ca section

[ CA_default ]

dir            = .                         # top dir
database       = \$dir/index.txt           # index file.
new_certs_dir  = \$dir/certs               # new certs dir

certificate    = \$dir/ca.cert.pem         # The CA cert
serial         = \$dir/serial              # serial no file
private_key    = \$dir/private/ca.key.pem  # CA private key
RANDFILE       = \$dir/private/.rand       # random number file

default_startdate = 19700101000000Z
default_enddate = 99991231235959Z
default_crl_days= 30                       # how long before next CRL
default_md     = sha256                    # md to use

policy         = policy_any                # default policy
email_in_dn    = no                        # Don't add the email into cert DN

name_opt       = ca_default                # Subject name display option
cert_opt       = ca_default                # Certificate display option
copy_extensions = none                     # Don't copy extensions from request

[ policy_any ]
organizationName       = match
commonName             = supplied

[ req ]
default_bits           = 4096
distinguished_name     = req_distinguished_name
x509_extensions        = v3_leaf
encrypt_key = no
default_md = sha256
attributes             = req_attributes
prompt                 = no
input_password         = rauc
output_password        = rauc

[ req_attributes ]
challengePassword              = Robust Auto-Update Controller

[ req_distinguished_name ]
commonName                     = Common Name (eg, YOUR name)
commonName_max                 = 64

[ v3_ca ]

subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer:always
basicConstraints = CA:TRUE

[ v3_inter ]

subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer:always
basicConstraints = CA:TRUE,pathlen:0

[ v3_leaf ]

subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer:always
basicConstraints = CA:FALSE
EOF

	export OPENSSL_CONF=$BASE/openssl.cnf

	cd $BASE

	echo "Development CA"
	openssl req -config $OPENSSL_CONF -newkey rsa:4096 -keyout private/ca.key.pem -out ca.csr.pem -subj "/O=$ORG/CN=$ORG $CA Development"

	openssl ca -config $OPENSSL_CONF -batch -selfsign -extensions v3_ca -in ca.csr.pem -out ca.cert.pem -keyfile private/ca.key.pem

	echo "Development Signing Keys 1"
	openssl req -config $OPENSSL_CONF -newkey rsa:4096 -keyout private/development-1.key.pem -out development-1.csr.pem -subj "/O=$ORG/CN=$ORG Development-1"
	openssl ca -config $OPENSSL_CONF -batch -extensions v3_leaf -in development-1.csr.pem -out development-1.cert.pem
}

#
# This is a demonstration of what you would want to put in a site.conf
# It's taken from another script I made that does a lot of other things, and as this script is not meant to be run inside Yocto (in this particular version),
# the following function is just a nice to have demonstration, for people to understand some of the advantages of a site.conf, and seeing useful things inside it
#
update_site_conf() {
	if [ -n "$BUILDDIR" ] ; then
		echo "Assuming you are running in a yocto project build"
		CONFFILE=${BUILDDIR}/conf/site.conf
	else
		echo "Not running in Yocto - showing a nice local preparation"
		BUILDDIR="SEDPLACEHOLDER"
		CONFFILE=$BASE/site.conf
	fi

	echo ""
	echo "Writing RAUC key configuration to site.conf ..."

	if test -f $CONFFILE; then
		if grep -q "^RAUC_KEYRING_FILE.*=" $CONFFILE; then
			echo "RAUC_KEYRING_FILE already configured, aborting key configuration"
			exit 0
		fi
		if grep -q "^RAUC_KEY_FILE.*=" $CONFFILE; then
			echo "RAUC_KEY_FILE already configured, aborting key configuration"
			exit 0
		fi
		if grep -q "^RAUC_CERT_FILE.*=" $CONFFILE; then
			echo "RAUC_CERT_FILE already configured, aborting key configuration"
			exit 0
		fi
	fi

	echo "RAUC_KEYRING_FILE=\"${BUILDDIR}/example-ca/ca.cert.pem\"" >> $CONFFILE
	echo "RAUC_KEY_FILE=\"${BUILDDIR}/example-ca/private/development-1.key.pem\"" >> $CONFFILE
	echo "RAUC_CERT_FILE=\"${BUILDDIR}/example-ca/development-1.cert.pem\"" >> $CONFFILE

	echo "Key configuration successfully written to ${BUILDDIR}/conf/site.conf"
}

main() {
	set -e
	init_env
	create_pki
	update_site_conf
}

main $@
