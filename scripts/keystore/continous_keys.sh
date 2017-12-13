#!/bin/sh

# FIXME
# - grab stats from each gnupg key creation, so that you can come up with
# performance metrics

KEYSTORE_DIR=$(dirname $0)

while /bin/true;
do
    OUTDATE=$(date +%d%b%Y)
    echo "Creating new GPG key folder in /dev/shm/${OUTDATE}";
    time sh ${KEYSTORE_DIR}/gnupg-batch.sh \
        --output ${HOME}/Docs/new_keys/${OUTDATE} \
        --count 5 \
        --dicepath ~/src/perl.git/diceware \
        --list ~/src/perl.git/diceware/diceware.wordlist.asc \
        --tempdir /dev/shm/${OUTDATE}
done
