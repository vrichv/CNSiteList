#!/bin/bash

processed_files=()
extra_file="my-extra.txt"

extract_domains() {
    local file="$1"

    # Check if file was already processed (avoid infinite recursion)
    for processed in "${processed_files[@]}"; do
        if [[ "$processed" == "$file" ]]; then
            return
        fi
    done

    # Add to processed files
    processed_files+=("$file")

    # Check if file exists
    if [[ ! -f "$file" ]]; then
        echo "Warning: File $file not found" >&2
        return
    fi

    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # Remove any trailing comments first
        line="${line%%#*}"
        # Trim whitespace
        line="$(echo "$line" | tr -d '[:space:]')"
        [[ -z "$line" ]] && continue

        # Handle includes after comments removed
        if [[ "$line" =~ ^include: ]]; then
            included_file="${line#include:}"
            extract_domains "$included_file"
        # Handle regular domains (skip lines starting with @)
        elif [[ ! "$line" =~ ^@ ]]; then
            [[ -n "$line" ]] && echo "$line"
        fi
    done < "$file"
}

# Main execution
cd "$(dirname "$0")"  # Change to script directory

# Create temporary file for all domains
temp_file=tmp_file1
temp_file2=tmp_file2

if [ -f "$extra_file" ]; then
    grep -v "\.cn" "$extra_file" |grep -v "^#" >> "geolocation-cn"
fi
# Extract domains from geolocation-cn and all included files
extract_domains "geolocation-cn" | sort -u > "$temp_file"

grep -v "\.cn" "$temp_file" |grep -v "^#"|grep -v "@ads" |grep -v ":" |grep -v "@\!cn" >"$temp_file2"
sed -i  's/@cn//g' "$temp_file2"
cat "$temp_file2" | while read domain; do echo "$domain" | rev | cut -d. -f1-2 | rev; done | sort -u >"$temp_file"
 (echo -n "[/"; tr '\n' '/' < "$temp_file"; echo "]https://223.5.5.5/dns-query") > cn-domain-agh.txt
mv "$temp_file" "cn-domain.txt"

count=$(wc -l < cn-domains.txt)
echo "Processed $count unique domains"
