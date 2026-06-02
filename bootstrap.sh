#!/usr/bin/env bash
set -euo pipefail

clone_or_pull() {
    local repo="$1"
    local dir="$2"
    if [ -d "$dir/.git" ]; then
        echo "Pulling latest $dir..."
        git -C "$dir" pull --ff-only
    else
        echo "Cloning $repo into $dir..."
        git clone "$repo" "$dir"
    fi
}

clone_or_pull https://github.com/duganbrettc/cascade-xclone-v34q-db db
clone_or_pull https://github.com/duganbrettc/cascade-xclone-v34q-api api
clone_or_pull https://github.com/duganbrettc/cascade-xclone-v34q-web web
