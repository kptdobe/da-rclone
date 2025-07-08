#!/bin/bash

# copies single buckets into da-content/<bucket-name>
# input is list-copy.txt, output is done-copy.txt

START_ALL=$(date +%s)

echo "Starting sync for all buckets at $(date)"

sync_bucket() {
  BUCKET_NAME="$1"
  LOG_FILE="log-copy-${BUCKET_NAME}.txt"
  START_TIME=$(date +%s)
  echo "[${BUCKET_NAME}] Sync started at $(date)"
  SRC="cm-r2:${BUCKET_NAME}-content"
  DST="hlx-r2:da-content/${BUCKET_NAME}"

  # Run rclone copy with progress, forward all output to log file
  if ! rclone copy "$SRC" "$DST" -v --progress --transfers 100 --inplace --no-check-dest --fast-list --checkers 32 > "$LOG_FILE" 2>&1; then
    echo "[${BUCKET_NAME}] Error copying. See $LOG_FILE for details." >&2
  else
    END_TIME=$(date +%s)
    DURATION=$((END_TIME-START_TIME))
    # Extract transferred size and number of files from log
    TRANSFERRED_SIZE=$(grep 'Transferred:' "$LOG_FILE" | grep -E 'B|KiB|MiB|GiB' | tail -1 | awk '{print $2, $3}')
    NUM_FILES=$(grep 'Transferred:' "$LOG_FILE" | grep -vE 'B|KiB|MiB|GiB' | tail -1 | awk '{print $4}' | tr -d ',')
    echo "[${BUCKET_NAME}] Copy completed successfully."
    echo "$BUCKET_NAME, ${DURATION}s, $TRANSFERRED_SIZE, $NUM_FILES" >> done-copy.txt
    echo "[${BUCKET_NAME}] Copy ended at $(date) (Duration: ${DURATION}s)"
    rm -f "$LOG_FILE"
    return
  fi
  END_TIME=$(date +%s)
  DURATION=$((END_TIME-START_TIME))
  echo "[${BUCKET_NAME}] Copy ended at $(date) (Duration: ${DURATION}s)"
}

# Export the function for use in subshells
export -f sync_bucket

# Read bucket names and run up to 5 in parallel
cat list-copy.txt | xargs -n1 -P5 -I{} bash -c 'sync_bucket "$@"' _ {}

END_ALL=$(date +%s)
TOTAL_DURATION=$((END_ALL-START_ALL))
echo "All copies completed at $(date) (Total duration: ${TOTAL_DURATION}s)" 