#!/bin/bash

# Usage: ./copyone.sh <bucketname> <filepath>

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <bucketname> <filepath>" >&2
  exit 1
fi

BUCKET="$1"
FILEPATH="$2"

# file path might start with a /
if [[ "$FILEPATH" == /* ]]; then
  FILEPATH="${FILEPATH:1}"
fi

SRC="cm-r2:${BUCKET}-content/$FILEPATH"
DST="hlx-r2:aem-content/${BUCKET}/${FILEPATH}"

# print the src and dst
echo "SRC: $SRC"
echo "DST: $DST"

# Run rclone copy for a single file
rclone copyto "$SRC" "$DST" -vv --dump headers --ignore-times --progress --inplace --fast-list --metadata --no-gzip-encoding --s3-decompress --metadata-set content-encoding=identity
