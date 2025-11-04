#!/bin/bash

make all
# Run QEMU with the appropriate options
qemu-system-x86_64 -drive format=raw,file=build/zigumi.iso -m 1G -smp 2 -enable-kvm -boot d