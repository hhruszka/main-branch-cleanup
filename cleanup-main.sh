#!/bin/bash

# 1. SELF-PRESERVATION
if [[ "$0" != "/tmp/clean_pro.sh" ]]; then
    cp "$0" /tmp/clean_pro.sh
    chmod +x /tmp/clean_pro.sh
    exec /tmp/clean_pro.sh "$@"
fi

# 2. ARGUMENT CHECK
if [ -z "$1" ]; then
    echo "❌ Usage: ./clean_pro.sh <path_to_mapping_file.csv>"
    exit 1
fi
MAPPING_FILE="$1"

# 3. CONFIGURATION
NEW_BRANCH="main-clean"
TAG_PATTERN="v*" 
TAGS=($(git tag -l "$TAG_PATTERN" --sort=v:refname))
INITIAL_COMMIT=$(git rev-list --max-parents=0 HEAD)

echo "🚀 Starting Mapped History Rebuild..."
echo "tag,old_hash,new_hash,date" > "$MAPPING_FILE"

git checkout -b $NEW_BRANCH $INITIAL_COMMIT

# 4. LOOP
for TAG in "${TAGS[@]}"
do
    echo "--------------------------------------"
    echo "🔍 Processing Tag: $TAG"

    OLD_HASH=$(git rev-parse "$TAG")
    ORIGINAL_MSG=$(git show -s --format=%B "$TAG")
    TAG_DATE=$(git log -1 --format=%aI "$TAG")
    
    git rm -rf . > /dev/null
    git checkout "$TAG" -- .
    
    if [ -n "$(git status --porcelain)" ]; then
        git add .
        FULL_MSG=$(printf "%s\n\nOriginal-Tag: %s\nOriginal-Hash: %s" "$ORIGINAL_MSG" "$TAG" "$OLD_HASH")
        
        GIT_AUTHOR_DATE="$TAG_DATE" GIT_COMMITTER_DATE="$TAG_DATE" \
        git commit -m "$FULL_MSG"
        
        NEW_HASH=$(git rev-parse HEAD)

        if [ -z "$(git diff HEAD $OLD_HASH)" ]; then
            echo "✅ VERIFIED: $TAG content matches."
            git tag -f "$TAG"
            # Write to CSV
            echo "$TAG,$OLD_HASH,$NEW_HASH,$TAG_DATE" >> "$MAPPING_FILE"
        else
            echo "❌ ERROR: Content mismatch at $TAG!"
            exit 1
        fi
    fi
done

echo "--------------------------------------"
echo "⭐ SUCCESS: History rebuilt."
echo "📄 Mapping file saved to: $MAPPING_FILE"
