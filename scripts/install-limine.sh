#!/bin/bash

# This script installs the Limine bootloader for Zigumi OS.

set -e

# Define the Limine directory
LIMINE_DIR="boot"

# Create the Limine directory if it doesn't exist
mkdir -p "$LIMINE_DIR"

# Download Limine
echo "Downloading Limine..."
curl -L -o "$LIMINE_DIR/limine.zip" "https://github.com/limine-bootloader/limine/archive/refs/heads/master.zip"

# Unzip Limine
echo "Unzipping Limine..."
unzip -o "$LIMINE_DIR/limine.zip" -d "$LIMINE_DIR"

# Move necessary files to the boot directory
echo "Moving Limine files..."
mv "$LIMINE_DIR/limine-master/limine.cfg" "$LIMINE_DIR/"
mv "$LIMINE_DIR/limine-master/stage2.bin" "$LIMINE_DIR/"
mv "$LIMINE_DIR/limine-master/limine.sys" "$LIMINE_DIR/"

# Clean up
rm -rf "$LIMINE_DIR/limine-master"
rm "$LIMINE_DIR/limine.zip"

echo "Limine bootloader installed successfully."