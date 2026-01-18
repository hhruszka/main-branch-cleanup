#!/bin/bash

if [ -z "$1" ]; then
    echo "❌ Usage: ./restore_pro.sh <path_to_mapping_file.csv>"
    exit 1
fi
MAP_FILE="$1"

echo "🔄 Reversing history cleanup using $MAP_FILE..."

# Skip the header line and read CSV
tail -n +2 "$MAP_FILE" | while IFS=',' read -r tag old_hash new_hash date
do
    if [ -n "$tag" ] && [ -n "$old_hash" ]; then
        echo "⏪ Restoring $tag to $old_hash"
        git tag -f "$tag" "$old_hash"
    fi
done

echo "✅ Restoration complete."
