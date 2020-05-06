#!/bin/sh

set -e

if [ $# -lt 1 ]; then
    echo "Missing VM name."
    exit
fi

if [ $UID != 0 ]; then
    echo "Need to run as root."
    exit
fi

FEDORA_VERSION="31"
VM_NAME="$1"
DISK_IMAGE="$VM_NAME.qcow2"
ROOT_PASSWORD="password"
CPUS="6"
RAM="10240"
VIRT_NETWORK="devstack-numa"

virt-builder fedora-$FEDORA_VERSION \
    --size 50G --update --selinux-relabel --format qcow2 \
    --output /var/lib/libvirt/images/$DISK_IMAGE \
    --root-password password:$ROOT_PASSWORD \
    --ssh-inject root:string:ssh-rsa\ AAAAB3NzaC1yc2EAAAADAQABAAABAQDu7wacqEBNFL1K4rCAMFERAeWwm00R+TQcEgq22fzVX4hBNjy3aKAtVR6mK0ieG71UrCkRRIMjX9Pt92kbgUuy+EyaKLUaF/NMxXORcgKu50dfs4L8SxYBRylUy/eFrnYlWePA4U+lBn7GSJ9SlpPw7g0cS2JKpu8dDH8SuyJMLIjfh3GEgsTcgn+9nJIHLNTxlxNiA9dxPt+1YTxTo2NZfbcnvm9fCdgLeZdy/5dl6Xks7vtMWeTbyO46dpfKP93rcEuH4XutU7zHUNErHUGZSqittEPa1jh30zQ2BuEjkrqwRu7VgEHLI6VyG/FEa6ulwfu59ITXG2grH2+dPmor\ artom@jayne \
    --hostname $VM_NAME \

virt-install --import --nographics --noautoconsole \
    --os-variant "fedora$FEDORA_VERSION" \
    --machine q35 \
    --vcpus $CPUS \
    --ram $RAM \
    -w network=$VIRT_NETWORK,model=virtio \
    --disk /var/lib/libvirt/images/$DISK_IMAGE \
    --name $VM_NAME
