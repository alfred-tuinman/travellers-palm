#!/usr/bin/env bash
# rename_media.sh
# Renames images and videos:
#   - Removes leading IMG-, IMG_, IMG, VID-, VID_, or VID
#   - Ensures a hyphen after the first 8 digits
#   - Replaces underscore with hyphen after first 8 digits

shopt -s nullglob    # Avoid errors if no files match

for f in IMG* VID*; do
    # Skip directories
    [[ -d "$f" ]] && continue

    newname="$f"

    # 1. Remove leading IMG or VID (optional - or _), only if followed by a digit
    newname=$(echo "$newname" | sed -E 's/^(IMG|VID)[-_]?([0-9])/\2/')

    # 2. Insert hyphen after the first 8 digits if not already there
    newname=$(echo "$newname" | sed -E 's/^([0-9]{8})([^-_])/\1-\2/')

    # 3. Replace underscore after the first 8 digits with hyphen
    newname=$(echo "$newname" | sed -E 's/^([0-9]{8})_(.*)/\1-\2/')

    # 4. Rename only if different and not empty
    if [[ -n "$newname" && "$f" != "$newname" ]]; then
        echo "Renaming: $f  →  $newname"
        mv -- "$f" "$newname"
    fi
done

echo "Done."
