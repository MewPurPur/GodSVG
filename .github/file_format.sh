#!/usr/bin/env bash
# This script ensures proper POSIX text file formatting and a few other things.
set -uo pipefail
IFS=$'\n\t'

# Function to check if file is UTF-8.
is_utf8() {
	local file="$1"
	# Use file command if available, otherwise assume UTF-8.
	if command -v file >/dev/null 2>&1; then
		file -b --mime-encoding "$file" | grep -q "utf-8\|ascii"
	else
		return 0  # Assume UTF-8 if can't check.
	fi
}

# Function to convert CRLF to LF.
convert_line_endings() {
	local file="$1"
	# Check if file has CRLF endings.
	if grep -q $'\r$' "$file" 2>/dev/null; then
		# Convert CRLF to LF using sed.
		sed -i 's/\r$//' "$file"
		echo "Converted CRLF to LF: $file"
	fi
}

# Function to remove trailing spaces and ensure final newline.
clean_whitespace() {
	local file="$1"
	# Remove trailing spaces and ensure final newline.
	sed -i -e '/[^ \t]/ s/[ \t]*$//' -e '/^[ \t]*$/ s/ *$//' -e '$a\' "$file"
}

# Loops through all text files tracked by Git.
git grep -zIl '' |
while IFS= read -rd '' f; do
	# Exclude some types of files.
	if [[ "$f" == *"svg" ]]; then
		continue
	elif [[ "$f" == *"build" ]]; then
		continue
	fi
	
	if ! is_utf8 "$f"; then
		echo "Warning: $f may not be UTF-8 encoded"
	fi
	
	convert_line_endings "$f"
	clean_whitespace "$f"
	
	# Remove the character sequence "== true" if it has a leading space.
	sed -i 's/ [=][=] true//g' "$f"
	
	# We don't want to change lines around braces in godot/tscn files.
	if [[ "$f" == *"godot" ]] || [[ "$f" == *"tscn" ]]; then
		continue
	fi
	
	# Disallow empty lines after the opening brace.
	sed -i ':a;N;$!ba;s/{\n\n/{\n/g' "$f"
	
	# Disallow some empty lines before the closing brace.
	sed -i ':a;N;$!ba;s/\n\n}/\n}/g' "$f"
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
printf "\n*** Aborting, please fix the formatting issue(s).\n"
rm -f patch.patch
exit 1
