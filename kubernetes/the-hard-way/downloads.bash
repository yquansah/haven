#!/bin/bash

while IFS=' ' read -r url filename; do
    echo "Downloading $filename from $url..."
    curl -L -o "$filename" "$url"
done < "downloads.txt"
