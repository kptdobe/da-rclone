#!/bin/bash

# re-syncs buckets that have changed in the last <MAX_AGE>

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <LIST_FILE> <MAX_AGE> (e.g., ./resync.sh list-resync.txt 10m)" >&2
  exit 1
fi
LIST_FILE="$1"
MAX_AGE="$2"
export MAX_AGE

START_ALL=$(date +%s)

echo "Starting re-sync for all buckets at $(date)"

sync_bucket() {
  BUCKET_NAME="$1"
  LOG_FILE="log-resync-${BUCKET_NAME}.txt"
  DUMP_FILE="dump-resync-${BUCKET_NAME}.txt"
  START_TIME=$(date +%s)
  echo "[${BUCKET_NAME}] Sync started at $(date)"
  SRC="cm-r2:${BUCKET_NAME}-content"
  DST="hlx-r2:aem-content/${BUCKET_NAME}"

  # Start rclone in the background
  rclone sync --transfers 100 --checkers 200 -vv --log-file="$DUMP_FILE" --dump headers --progress --inplace --ignore-checksum --fast-list --max-age "$MAX_AGE" --metadata --ignore-size "$SRC" "$DST" > "$LOG_FILE" 2>&1 &
  RCLONE_PID=$!

  # Monitor the dump file for changes in the foreground
  TIMEOUT=0
  while kill -0 $RCLONE_PID 2>/dev/null; do
    if [ -f "$DUMP_FILE" ]; then
      NOW=$(date +%s)
      MODIFIED=$(stat -f %m "$DUMP_FILE")
      AGE=$((NOW - MODIFIED))
      if [ $AGE -ge 15 ]; then
        echo "[${BUCKET_NAME}] Dump file unchanged for 15s, killing rclone (PID $RCLONE_PID)" >&2
        kill $RCLONE_PID
        wait $RCLONE_PID 2>/dev/null
        echo "[${BUCKET_NAME}] Resync killed due to inactivity (timeout)."
        TIMEOUT=1
        break
      fi
    fi
    sleep 2
  done

  wait $RCLONE_PID
  STATUS=$?
  END_TIME=$(date +%s)
  DURATION=$((END_TIME-START_TIME))
  TRANSFERRED_SIZE=$(grep 'Transferred:' "$LOG_FILE" | grep -E 'B|KiB|MiB|GiB' | tail -1 | awk '{print $2, $3}')
  NUM_FILES=$(grep 'Transferred:' "$LOG_FILE" | grep -vE 'B|KiB|MiB|GiB' | tail -1 | awk '{print $4}' | tr -d ',')

  if [ "$TIMEOUT" -eq 1 ]; then
    echo "$BUCKET_NAME, ${DURATION}s, $TRANSFERRED_SIZE, $NUM_FILES, TIMEOUT" >> done-resync.txt
    rm -f "$LOG_FILE" "$DUMP_FILE"
    return 0
  elif [ $STATUS -eq 0 ]; then
    echo "[${BUCKET_NAME}] Resync completed successfully."
    echo "$BUCKET_NAME, ${DURATION}s, $TRANSFERRED_SIZE, $NUM_FILES" >> done-resync.txt
    echo "[${BUCKET_NAME}] Resync ended at $(date) (Duration: ${DURATION}s)"
    rm -f "$LOG_FILE" "$DUMP_FILE"
    return 0
  else
    echo "[${BUCKET_NAME}] Resync ended with error or was killed. (Duration: ${DURATION}s)" >&2
    return 1
  fi
}

# Export the function for use in subshells
export -f sync_bucket

# Read bucket names and run up to 5 in parallel
cat "$LIST_FILE" | xargs -n1 -P5 -I{} bash -c 'sync_bucket "$@"' _ {}

END_ALL=$(date +%s)
TOTAL_DURATION=$((END_ALL-START_ALL))
echo "All re-syncs completed at $(date) (Total duration: ${TOTAL_DURATION}s)" 