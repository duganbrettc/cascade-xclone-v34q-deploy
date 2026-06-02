#!/usr/bin/env bash
set -euo pipefail

clone_or_pull() {
    local repo="$1"
    local dir="$2"
    if [ -d "$dir/.git" ]; then
        echo "Updating $dir from origin/HEAD..."
        git -C "$dir" fetch origin
        git -C "$dir" reset --hard origin/HEAD
    else
        echo "Cloning $repo into $dir..."
        git clone "$repo" "$dir"
    fi
}

clone_or_pull https://github.com/duganbrettc/cascade-xclone-v34q-db db
clone_or_pull https://github.com/duganbrettc/cascade-xclone-v34q-api api
clone_or_pull https://github.com/duganbrettc/cascade-xclone-v34q-web web
