#!/bin/bash

# Extend PATH to include common locations for binaries

exec >> ~/Downloads/hazel_script_output.log 2>&1
echo "Script started at $(date)"

PDF="$1"

echo "Start encrypted PDF conversion"
echo "Processing file: $PDF"

# Validate input file
if [ ! -f "$PDF" ]; then
    echo "$(date) | FILE NOT FOUND | $PDF" >> "$LOGFILE"
    echo "Error: File not found: $PDF"
    exit 1
fi

if [[ "${PDF##*.}" != "pdf" ]]; then
    echo "$(date) | INVALID FILE TYPE | $PDF" >> "$LOGFILE"
    echo "Error: Invalid file type. Only PDF files are supported: $PDF"
    exit 1
fi
LOGFILE=~/Downloads/decryption_failures.log

echo "Environment variables:" >> ~/Downloads/hazel_debug.log
env >> ~/Downloads/hazel_debug.log
echo "PATH: $PATH" >> ~/Downloads/hazel_debug.log

# Helper function to prepend "encrypted_" to filename
mark_as_encrypted() {
    DIR=$(dirname "$PDF")
    BASE=$(basename "$PDF")
    NEWNAME="${DIR}/encrypted_${BASE}"
    "$MV_PATH" "$PDF" "$NEWNAME"
    echo "Marked as encrypted: $NEWNAME"
}

# Extract source URL if available
SOURCE=$(xattr -p com.apple.metadata:kMDItemWhereForms "$PDF" 2>/dev/null | tr -d '\n')
if [ $? -ne 0 ]; then
    echo "$(date) | METADATA EXTRACTION FAILED | $PDF" >> "$LOGFILE"
    SOURCE="Unknown"
fi

# Determine company from filename or URL
FILENAME=$(basename "$PDF")
COMPANY=""

echo "Hazel asked to examine the file: $FILENAME"

# Match based on filename
if [[ "$FILENAME" == *"PDF_RPNT_"* ]]; then
    COMPANY="singtel"
# elif [[ "$FILENAME" == *"globex"* ]]; then
#    COMPANY="globex"
# Match based on download source
# elif echo "$SOURCE" | grep -qi 'acmebank.com'; then
#    COMPANY="acme_corp"
# elif echo "$SOURCE" | grep -qi 'globexenergy.com'; then
#    COMPANY="globex"
else
    echo "$(date) | UNKNOWN SOURCE | $FILENAME | $SOURCE" >> "$LOGFILE"
    echo "No matching password rule for file: $FILENAME"
    exit 0
fi

# Full paths for commands
QPDF_PATH=$(which qpdf)
SECURITY_PATH=$(which security)
MV_PATH=$(which mv)

# Check if encrypted
# Must hardcode the path because hazel doesn't support changing the path variable https://www.noodlesoft.com/manual/hazel/attributes-actions/using-shell-scripts/
if /opt/homebrew/bin/qpdf --is-encrypted "$PDF"; then
    # Retrieve password from Keychain
    PASSWORD=$("$SECURITY_PATH" find-generic-password -a "$COMPANY" -s PDFPassword -w 2>/dev/null)
    if [ -z "$PASSWORD" ]; then
        echo "$(date) | MISSING PASSWORD | $PDF | $SOURCE" >> "$LOGFILE"
        echo "Password not found for company: $COMPANY. Unable to decrypt file: $PDF"
        exit 0
    fi
    TMPFILE=$(mktemp "/tmp/${FILENAME%.pdf}_decrypted_XXXXXX.pdf")
    trap 'rm -f "$TMPFILE"' EXIT

    if /opt/homebrew/bin/qpdf --decrypt --password="$PASSWORD" "$PDF" "$TMPFILE"; then
        "$MV_PATH" "$TMPFILE" "$PDF"
        echo "Successfully decrypted: $FILENAME"
    elif [ $? -eq 3 ]; then
        "$MV_PATH" "$TMPFILE" "$PDF"
        echo "Decryption completed with warnings: $FILENAME"
    else
        echo "Decryption failed for $FILENAME"
        echo "$(date) | DECRYPTION FAILED | $FILENAME | $SOURCE" >> "$LOGFILE"
        rm -f "$TMPFILE"
        echo "Decryption failed. Unable to process file: $PDF"
        mark_as_encrypted
        exit 0
    fi
else
    echo "$(date) | NOT ENCRYPTED | $PDF" >> "$LOGFILE"
    echo "File is not encrypted: $PDF"
fi
