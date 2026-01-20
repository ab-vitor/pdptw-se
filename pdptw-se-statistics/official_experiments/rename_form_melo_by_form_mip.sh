#!/usr/bin/env bash
set -euo pipefail

root="${1:-.}"

find "$root" -type f -name '*csvresults_form_melo*' -print0 |
while IFS= read -r -d '' file; do
    dir="$(dirname "$file")"
    base="$(basename "$file")"
    newbase="${base//csvresults_form_melo/csvresults_form_mip}"
    dest="$dir/$newbase"

    [ "$file" = "$dest" ] && continue

    if [ -e "$dest" ]; then
        printf 'Skipping (target exists): %s -> %s\n' "$file" "$dest" >&2
        continue
    fi

    printf 'Renaming: %s -> %s\n' "$file" "$dest"
    mv -- "$file" "$dest"
done