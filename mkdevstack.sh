#!/bin/sh

if [ $# -lt 1 ]; then
    echo "Missing output image filename."
    exit 
fi

output_image=$1

virt-builder -o $output_image --size 50G --update --selinux-relabel \
    --format qcow2 \
    --install git,vim \
    --run runscript.sh \
    fedora-30
