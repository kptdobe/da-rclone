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

`./copy.sh` makes a full copy of a bucket from `cm-r2` to `hlx-r2`

`./resync.sh` makes a sync of the diff between the 2 buckets but in one direction only: from `cm-r2` to `hlx-r2`

## Useful

### Get the size of a bucket

```
rclone size --fast-list --checkers 32 cm-r2:adobecom-content
```

### Get the size of a folder in a bucket

```
rclone size --fast-list --checkers 32 hlx-r2:da-content/adobecom 
```