#!/bin/bash
# generate-id.sh - Generate semantic ID from description
# Usage: bash generate-id.sh <flow_type> <description>

set -e

FLOW_TYPE="${1:-}"
DESCRIPTION="${2:-}"

if [ -z "$FLOW_TYPE" ] || [ -z "$DESCRIPTION" ]; then
    echo "Usage: bash generate-id.sh <flow_type> <description>"
    echo "Flow types: FEATURE, FIX, ANALYZE, REFACTOR"
    exit 1
fi

# Normalize flow type
FLOW_TYPE=$(echo "$FLOW_TYPE" | tr '[:lower:]' '[:upper:]')

# Extract significant words from description
# Remove common words and take first 3-4 significant words
extract_keywords() {
    local text="$1"

    # Common words to remove (Russian and English)
    local stop_words="добавить исправить починить проверить проанализировать найти создать реализовать интегрировать консолидировать заменить вынести упростить разбить add fix check analyze find create implement integrate consolidate replace extract simplify split the a an in for to of and or with by from с в на для и или по от из при"

    # Convert to lowercase
    text=$(echo "$text" | tr '[:upper:]' '[:lower:]')

    # Remove punctuation
    text=$(echo "$text" | tr -d '[:punct:]')

    # Remove stop words
    for word in $stop_words; do
        text=$(echo "$text" | sed "s/\b${word}\b//g")
    done

    # Extract words
    local words=$(echo "$text" | tr ' ' '\n' | grep -v '^$')

    # Take first 3 significant words
    local selected=$(echo "$words" | head -3)

    # Convert to uppercase and join with hyphens
    local result=""
    for word in $selected; do
        # Take first 6 chars of each word
        local short=$(echo "$word" | cut -c1-6)
        if [ -n "$result" ]; then
            result="${result}-${short}"
        else
            result="$short"
        fi
    done

    echo "$result" | tr '[:lower:]' '[:upper:]'
}

# Get next available number
get_next_number() {
    local prefix="$1"
    local number=1

    # Try to find existing issues with same prefix
    # This is a simplified version - in production would query beads
    for i in $(seq 1 100); do
        local test_id="${prefix}-$(printf '%03d' $i)"
        if ! bd show "bd-${test_id}" &>/dev/null 2>&1; then
            number=$i
            break
        fi
    done

    echo $number
}

# Main logic
KEYWORDS=$(extract_keywords "$DESCRIPTION")
SEMANTIC_PART="${KEYWORDS}"

# Limit semantic part to 20 chars
SEMANTIC_PART=$(echo "$SEMANTIC_PART" | cut -c1-20)

# Get next number
NUMBER=$(get_next_number "${FLOW_TYPE}-${SEMANTIC_PART}")

# Format number with leading zeros
NUMBER_FORMATTED=$(printf '%03d' $NUMBER)

# Generate final ID
FINAL_ID="${FLOW_TYPE}-${SEMANTIC_PART}-${NUMBER_FORMATTED}"

# Output
echo "$FINAL_ID"
