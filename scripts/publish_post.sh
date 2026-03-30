#!/bin/sh

set -eu

if [ "$#" -lt 1 ]; then
  echo "Usage: scripts/publish_post.sh path/to/post.md [more-files...]" >&2
  exit 1
fi

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

post_file=$1

if [ ! -f "$post_file" ]; then
  echo "Post file not found: $post_file" >&2
  exit 1
fi

case "$post_file" in
  _posts/*) ;;
  *)
    echo "First argument must be a file inside _posts/: $post_file" >&2
    exit 1
    ;;
esac

basename_no_ext=$(basename "$post_file" .md)
year=$(printf '%s' "$basename_no_ext" | cut -d- -f1)
month=$(printf '%s' "$basename_no_ext" | cut -d- -f2)
day=$(printf '%s' "$basename_no_ext" | cut -d- -f3)
slug=$(printf '%s' "$basename_no_ext" | cut -d- -f4-)

title_line=$(sed -n 's/^title:[[:space:]]*//p' "$post_file" | head -n 1)
title=$(printf '%s' "$title_line" | sed 's/^"//; s/"$//')

if [ -z "$title" ]; then
  title="$slug"
fi

site_url=$(sed -n 's/^url:[[:space:]]*"\{0,1\}\(.*\)"\{0,1\}$/\1/p' _config.yml | head -n 1)
baseurl=$(sed -n 's/^baseurl:[[:space:]]*"\{0,1\}\(.*\)"\{0,1\}[[:space:]]*#\{0,1\}.*$/\1/p' _config.yml | head -n 1)

if [ -n "$baseurl" ]; then
  post_url="${site_url%/}/${baseurl#/}/${year}/${month}/${day}/${slug}/"
else
  post_url="${site_url%/}/${year}/${month}/${day}/${slug}/"
fi

git add "$@"

if git diff --cached --quiet; then
  echo "No staged changes to commit." >&2
  exit 1
fi

git commit -m "Publish post: $title"
git push origin main

printf 'Post published: %s\n' "$post_url"
