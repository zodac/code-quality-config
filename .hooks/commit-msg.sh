#!/bin/bash

# Allowed categories (alphabetised, one per line)
ALLOWED_CATEGORIES=(
    "CI"
    "CSS"
    "Docker"
    "Documentation"
    "Java"
    "JavaScript"
    "License"
    "Markdown"
    "Python"
    "TypeScript"
)

# Build regex alternation from array
category_pattern=$(printf '%s|' "${ALLOWED_CATEGORIES[@]}")
category_pattern="${category_pattern%|}"  # remove trailing |

regex="^\[(${category_pattern})\] .+"

commit_file="${1}"
line_number=0
error_found=0

while IFS= read -r line || [ -n "${line}" ]; do
    line_number=$((line_number + 1))
    
    # Allow empty lines
    if [[ -z "${line}" ]]; then
        continue
    fi
    
    if [[ ! "${line}" =~ ${regex} ]]; then
        echo "Invalid commit message:"
        echo "L${line_number}: '${line}'"
        echo
        error_found=$((error_found + 1))
    fi
done < "${commit_file}"

if [[ ${error_found} -gt 0 ]]; then
    echo "Each non-empty line must follow the format: '[Category] Commit message'"
    echo "Allowed categories: ${ALLOWED_CATEGORIES[*]}"
    exit 1
fi

exit 0
