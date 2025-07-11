# rclone scripts for DA migration

## Setup

Create 2 remotes `cm-r2` and `hlx-r2`: 

`rclone config`

```
[r2]
type = s3
provider = Cloudflare
access_key_id = ACCESS_KEY
secret_access_key = SECRET_ACCESS_KEY
region = auto
endpoint = https://ACCOUNT_ID.r2.cloudflarestorage.com
acl = private
```

Ask me or Chris for ACCES_KEY, SECRET_ACCESS_KEY and ACCOUNT_ID (2x, one set per remote)

## Usage

`./copy.sh list.txt` makes a full copy of the buckets from `cm-r2` to `hlx-r2`. list.txt is the list of bucket names (one per line, no "-content")

`./resync.sh list.txt 24h` makes a sync of the diff between the 2 buckets but in one direction only: from `cm-r2` to `hlx-r2`. list.txt is the list of bucket names (one per line, no "-content"). Time filters files to copy (modified in the last 24h...).

`./copyone.sh <bucketname> <file_path>` copies one file from `cm-r2` single bucket to `hlx-r2` `aem-content` bucket.

## Useful

### Get the size of a bucket

```
rclone size --fast-list --checkers 32 cm-r2:adobecom-content
```

### Get the size of a folder in a bucket

```
rclone size --fast-list --checkers 32 hlx-r2:aem-content/adobecom 
```

## KV

### Export

```
./kv.sh <account_id> <namespace_id> <api_token> kv.json
```

`<account_id>` is the id in the url on the CloudFlare url when you are in the source account
`<namespace_id>` is the KV entry id. Cloudflare UI: visit the KV, select the KV to feed (like `DA_CONFIG`) and copy its id!
`api_token` - create one here: https://dash.cloudflare.com/<account_id>/api-tokens

### Import

```
wrangler kv bulk put kv.json --remote --namespace-id <namespace_id>
```

`<namespace_id>` is the target namespace_id (where do you want to upload the entries)
`wrangler` asks you to the select the account.