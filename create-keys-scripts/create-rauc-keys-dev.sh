cd $(dirname ${BASH_SOURCE[0]})
pwd
set -euo pipefail

# The script is obviously dev, and the paths are like this as it is expected to be run in your docker environment
# where the paths match the conventions of the other scripts
set -a
: ${TARGET_KEYS_DIR=$HOME/pscg/customers/build-stuff/rauc/keys3}
: ${ORG="The PSCG"}
: ${CA="Example CA"}
: ${CRL="-crldays 5000"}
: ${KEY_GENERATION_WORKDIR=keys/example}
set +a

mkdir -p $TARGET_KEYS_DIR
echo "Creating your keys... working in: $KEY_GENERATION_WORKDIR --> flat result in $TARGET_KEYS_DIR"
./create-keys-impl.sh
cp $KEY_GENERATION_WORKDIR/example-ca/ca.cert.pem $TARGET_KEYS_DIR
cp $KEY_GENERATION_WORKDIR/example-ca/development-1.cert.pem $TARGET_KEYS_DIR
cp $KEY_GENERATION_WORKDIR/example-ca/private/development-1.key.pem $TARGET_KEYS_DIR

echo -e "\e[32mHooray, your keys are in $TARGET_KEYS_DIR\e[0m"
