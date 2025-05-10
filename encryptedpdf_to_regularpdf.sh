#!/bin/bash

PDF="$1"
LOGFILE=~/Downloads/decryption_failures.log

# Helper function to prepend "encrypted_" to filename
mark_as_encrypted() {
    DIR=$(dirname "$PDF")
    BASE=$(basename "$PDF")
    NEWNAME="${DIR}/encrypted_${BASE}"
    mv "$PDF" "$NEWNAME"
    echo "Marked as encrypted: $NEWNAME"
}

# Extract source URL if available
SOURCE=$(xattr -p com.apple.metadata:kMDItemWhereFroms "$PDF" 2>/dev/null | tr -d '\n')

# Determine company from filename or URL
FILENAME=$(basename "$PDF")
COMPANY=""

# Match based on filename
if [[ "$FILENAME" == *"acme"* ]]; then
    COMPANY="acme_corp"
elif [[ "$FILENAME" == *"globex"* ]]; then
    COMPANY="globex"
# Match based on download source
elif echo "$SOURCE" | grep -qi 'acmebank.com'; then
    COMPANY="acme_corp"
elif echo "$SOURCE" | grep -qi 'globexenergy.com'; then
    COMPANY="globex"
else
    echo "No matching password rule for: $FILENAME"
    echo "$(date) | UNKNOWN SOURCE | $FILENAME | $SOURCE" >> "$LOGFILE"
    mark_as_encrypted
    exit 1
fi

# Retrieve password from Keychain
PASSWORD=$(security find-generic-password -a "$COMPANY" -s PDFPassword -w 2>/dev/null)
if [ -z "$PASSWORD" ]; then
    echo "Password not found for $COMPANY"
    echo "$(date) | MISSING PASSWORD | $FILENAME | $SOURCE" >> "$LOGFILE"
    mark_as_encrypted
    exit 1
fi

# Check if encrypted
if qpdf --show-encryption "$PDF" | grep -q 'encrypted: yes'; then
    TMPFILE=$(mktemp "/tmp/${FILENAME%.pdf}_decrypted_XXXXXX.pdf")

    if qpdf --decrypt --password="$PASSWORD" "$PDF" "$TMPFILE"; then
        mv "$TMPFILE" "$PDF"
        echo "Successfully decrypted: $FILENAME"
    else
        echo "Decryption failed for $FILENAME"
        echo "$(date) | DECRYPTION FAILED | $FILENAME | $SOURCE" >> "$LOGFILE"
        rm -f "$TMPFILE"
        mark_as_encrypted
        exit 1
    fi
else
    echo "Not encrypted: $PDF"
fi
