#!/bin/bash

# List all buckets in the cm-r2 remote, extract bucket names, remove trailing '-content', and save to list.txt

rclone lsd cm-r2: | awk '{print $5}' | sed 's/-content$//' > list.txt