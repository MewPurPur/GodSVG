#!/usr/bin/env bash
# This script ensures proper POSIX text file formatting and a few other things.
set -uo pipefail
IFS=$'\n\t'

# Function to process a single file.
process_file() {
    local f="$1"
    # Exclude some types of files.
    if [[ "$f" == *"svg" ]]; then
        return
    fi
    # Ensure that files are UTF-8 formatted.
    recode UTF-8 "$f" 2> /dev/null
    # Ensure that files have LF line endings and do not contain a BOM.
    dos2unix "$f" 2> /dev/null
    # Remove trailing space characters and ensure that files end
    # with newline characters. -l option handles newlines conveniently.
    perl -i -ple 's/ *$//g' "$f"
    # Remove the character sequence "== true" if it has a leading space.
    perl -i -pe 's/\x20== true//g' "$f"
    # We don't want to change lines around braces in godot/tscn files.
    if [[ "$f" == *"godot" ]] || [[ "$f" == *"tscn" ]]; then
        return
    fi
    # Disallow empty lines after the opening brace.
    sed -z -i 's/\x7B\x0A\x0A/\x7B\x0A/g' "$f"
    # Disallow some empty lines before the closing brace.
    sed -z -i 's/\x0A\x0A\x7D/\x0A\x7D/g' "$f"
}

# Process all files passed as arguments.
for file in "$@"; do
    if [ -f "$file" ]; then
        process_file "$file"
    fi
done

git diff > patch.patch
FILESIZE="$(stat -c%s patch.patch)"
MAXSIZE=5
# If no patch has been generated all is OK, clean up, and exit.
if (( FILESIZE < MAXSIZE )); then
    printf "Files in this commit comply with the formatting rules.\n"
    rm -f patch.patch
    exit 0
fi
# A patch has been created, notify the user, clean up, and exit.
printf "\n*** The following differences were found between the code "
printf "and the formatting rules:\n\n"
cat patch.patch
printf "\n*** Aborting, please fix the formatting issue(s).'\n"
rm -f patch.patch
exit 1
