# Partial OTA creation example with RAUC

This code is a simple example of a specific customer requirement that will allow them to do a RAUC based A/B update without streaming or verity.

## Initial setup
While the customer's code is confidential and obviously more complex, this can be useful for the general public, and to use it you are required to create in this directory
a file called *local.config* as follows (replace `foo@bar` with your address , and baz with your expected bundle's `compatible` string`):
```
cat > local.config << 'EOF'
: ${SSH_USER_AT_HOST=foo@bar}
: ${RAUC_COMPATIBLE=baz}
export SSH_USER_AT_HOST RAUC_COMPATIBLE
EOF
```

For example, if you would to be compatible with the "awesomeo2000" machine, and scp to it via root@thepscg-demo.localhost, you would enter:
```
cat > local.config << 'EOF'
: ${SSH_USER_AT_HOST=root@thepscg-demo.local}
: ${RAUC_COMPATIBLE=awesomeo2000}
export SSH_USER_AT_HOST RAUC_COMPATIBLE
EOF
```

## Building and deploying example
Simply run the following script, and it will do everything needed:
```bash
./quick-test.sh
```

The script does not go crazy about error checking, after the first time it sets the materials, and is served as an example. In the first time it will also:
1. Create keys and certificates if there is no *keys* folder
2. Create a RAUC manifest if there is no *rauc/manifest.raucm* file

Then, and in subsequent runs, it will pack the bundle. You may and should replace the example with your own code, populate the keys with the actual keys you wish to populate, and so on.
