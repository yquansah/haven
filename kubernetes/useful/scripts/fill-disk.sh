#!/bin/bash

# The purpose of this script is to fill the disk of a Kubernetes node up to trigger a disk pressure taint from the kubelet.
# By default, the kubelet will place the taint on the node when the disk usage is greater than 85% of the total disk space.
# This is just for testing purposes.
TARGET_DIR="/tmp/disk-pressure-test"
mkdir -p "$TARGET_DIR"
echo "Filling disk at $TARGET_DIR..."

for i in $(seq 1 1000); do
    dd if=/dev/zero of="$TARGET_DIR/filler_$i" bs=1M count=1024 status=none
    echo "Wrote 1GiB to $TARGET_DIR/filler_$i"

    sleep 1
done

echo "Done writing files."
