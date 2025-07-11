#!/bin/bash

# Usage: ./export-kv.sh <ACCOUNT_ID> <NAMESPACE_ID> <API_TOKEN> <OUTPUT_FILE>
# Example: ./export-kv.sh abcd1234... 0123456789abcdef... CLOUDFLARE_API_TOKEN export.json

ACCOUNT_ID="$1"
NAMESPACE_ID="$2"
API_TOKEN="$3"
OUTPUT_FILE="$4"

if [ $# -ne 4 ]; then
  echo "Usage: $0 <ACCOUNT_ID> <NAMESPACE_ID> <API_TOKEN> <OUTPUT_FILE>"
  exit 1
fi

echo "Exporting all keys from namespace $NAMESPACE_ID..."

# Pagination variables
CURSOR=""
FIRST_ITEM=true

echo "[" > "$OUTPUT_FILE"
while : ; do
  if [ -z "$CURSOR" ]; then
    RESPONSE=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
      "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/storage/kv/namespaces/$NAMESPACE_ID/keys?limit=1000")
  else
    RESPONSE=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
      "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/storage/kv/namespaces/$NAMESPACE_ID/keys?limit=1000&cursor=$CURSOR")
  fi

  KEYS=$(echo "$RESPONSE" | jq -r '.result[]?.name')
  CURSOR=$(echo "$RESPONSE" | jq -r '.result_info.cursor // empty')

  for KEY in $KEYS; do
    VALUE=$(curl -s -H "Authorization: Bearer $API_TOKEN" \
      "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/storage/kv/namespaces/$NAMESPACE_ID/values/$KEY" | base64)
    if [ "$FIRST_ITEM" = true ]; then
      FIRST_ITEM=false
    else
      echo "," >> "$OUTPUT_FILE"
    fi
    echo "{\"key\":$(jq -R . <<< "$KEY"),\"value\":\"$VALUE\",\"base64\":true}" >> "$OUTPUT_FILE"
  done

  # Break if no more keys
  if [ -z "$CURSOR" ] || [ "$CURSOR" == "null" ]; then
    break
  fi

done
echo "]" >> "$OUTPUT_FILE"

echo "Export complete: $OUTPUT_FILE"