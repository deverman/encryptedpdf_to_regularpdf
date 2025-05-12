# Encrypted PDF to Regular PDF Conversion Script

This script is designed to work with Hazel rules to automatically decrypt encrypted PDFs using `qpdf`. It validates the file, retrieves the appropriate password from the macOS Keychain, and decrypts the file if possible.

## Features
- Automatically detects encrypted PDFs.
- Retrieves passwords securely from the macOS Keychain.
- Handles decryption warnings gracefully.
- Logs all operations for debugging and auditing.

---

### Note on Hazel 6.0
As of Hazel 6.0, Hazel includes the ability to read encrypted PDFs. However, this script was created because encrypted PDFs are often impractical. It is easy to forget the password or lose the email containing it, making the files inaccessible. This script simplifies the process by decrypting PDFs and replacing the encrypted versions with usable files.

## Important Assumptions
- **File Replacement**: The script assumes that replacing the encrypted file with the decrypted version is acceptable. If you need to keep the original encrypted file, you must modify the script accordingly.
- **Keychain Passwords**: The script assumes that all required passwords are stored in the macOS Keychain under the `PDFPassword` service. If a password is missing, the file will not be decrypted, and its name will be prefixed with `encrypted_`.
- **File Naming**: The script relies on specific patterns in file names (e.g., `PDF_RPNT_`) to determine the company or source. Ensure your file naming conventions align with the script's logic or update the script to match your requirements.

## Dependencies

### Required Tools
1. **qpdf**: A command-line tool for PDF transformation.
   - Install via Homebrew:
     ```bash
     brew install qpdf
     ```

2. **Hazel**: A macOS automation tool for managing files.
   - Download and install from [Noodlesoft](https://www.noodlesoft.com/).

3. **macOS Keychain**: Used to securely store and retrieve passwords.

---

## Setup Instructions

### 1. Add Passwords to Keychain
For each company or source requiring a password, add it to the macOS Keychain using the following command:
```bash
security add-generic-password -a <account_name> -s PDFPassword -w '<password>'
```
- Replace `<account_name>` with the identifier for the company or source (e.g., `acme_corp`).
- Replace `<password>` with the actual password.

Example:
```bash
security add-generic-password -a acme_corp -s PDFPassword -w 'mypassword123'
```

### 2. Configure Hazel Rule
1. Open Hazel Preferences.
2. Add a folder to monitor for encrypted PDFs.
3. Create a new rule matching all the following conditions:
   - **If**: `Name` does not start with "encrypted_".
   - **if**: Kind is PDF
   - **Do the following**:
     1. Run Shell Script:
        - Select the `encryptedpdf_to_regularpdf.sh` script.
        - Ensure the script has executable permissions:
          ```bash
          chmod +x /path/to/encryptedpdf_to_regularpdf.sh
          ```
     2. Continue Matching Rules:
        - Add an action called "Continue matching rules" after the "Run Shell Script" action. This ensures that Hazel evaluates subsequent rules for the same file. (If that is the desired behavior.)

## ❗️**Pro Tip: Prevent Double Processing**
After Hazel runs your decryption script, the file is technically “changed” (decrypted and overwritten), which can re-trigger the same Hazel rule. To avoid that:
- Set a Hazel condition to exclude files starting with `encrypted_` as recommended above.

### 3. Verify Script Path
Ensure the script is located in a directory accessible to Hazel. If necessary, hardcode the full path to `qpdf` in the script, as Hazel does not inherit the system `PATH`.

### 4. Edit the Script for Filename Matching
The script uses specific patterns in file names (e.g., `PDF_RPNT_*`) to determine the company or source. You must edit the script to include the correct filename matching logic for your company's PDFs. Look for the section in the script where filename patterns are matched and update it accordingly.

---

## Script Behavior
1. **Validation**:
   - Checks if the file exists and is a PDF.
2. **Encryption Check**:
   - Uses `qpdf --is-encrypted` to determine if the file is encrypted.
3. **Password Retrieval**:
   - Fetches the password from the Keychain using the `security` command.
4. **Decryption**:
   - Attempts to decrypt the file using `qpdf`.
   - Handles warnings gracefully (exit code `3`).
   - **Replaces the encrypted file with the decrypted version**: The original encrypted file will be deleted after successful decryption.
5. **Failure Handling**:
   - If the file cannot be decrypted, the script prefixes the file name with `encrypted_` to help you identify problematic files. You can then investigate and update your Keychain with the correct password for these files.
6. **Logging**:
   - Logs all operations to `~/Downloads/hazel_script_output.log` and `~/Downloads/hazel_debug.log`.

---

## Troubleshooting
- **qpdf Not Found**:
  Ensure `qpdf` is installed and its path is hardcoded in the script if necessary.
- **Password Not Found**:
  Verify the password is correctly added to the Keychain.
- **Script Not Executing**:
  Check Hazel logs and ensure the script has executable permissions.

---

## Example Keychain Entry
To add a password for a company named "singtel":
```bash
security add-generic-password -a singtel -s PDFPassword -w 'singtelpassword'
```

---

## Logs
- **Output Log**: `~/Downloads/hazel_script_output.log`
- **Debug Log**: `~/Downloads/hazel_debug.log`

Use these logs to debug any issues with the script or Hazel rule.

---

This script simplifies the process of decrypting PDFs and integrates seamlessly with Hazel for automation.
