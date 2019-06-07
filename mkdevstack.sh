#!/bin/sh

if [ -z "$MKDS_USER" ]; then
    echo "Please source mkdevstackrc before running this script."
    exit
fi
if [ $# -lt 1 ]; then
    echo "Missing VM name."
    exit
fi

TMP_RUNSCRIPT="/tmp/mkdevstack.runscript.sh"
TMP_FIRSTBOOT="/tmp/mkdevstack.firstboot.sh"
MKDS_VM_NAME="$1"
MKDS_DISK_IMAGE="$MKDS_VM_NAME.qcow2"

cat <<RUNSCRIPT > $TMP_RUNSCRIPT
password='`openssl passwd -6 $MKDS_USER_PASSWORD`'
useradd -G wheel -p "\$password" -m $MKDS_USER
SSH_DIR="/home/$MKDS_USER/.ssh"
mkdir \$SSH_DIR
chown $MKDS_USER:$MKDS_USER \$SSH_DIR
chmod 700 \$SSH_DIR
echo "$MKDS_SSH_PUBKEY" > \$SSH_DIR/authorized_keys
cat <<EOF > /home/$MKDS_USER/.gitconfig
[user]
	email = $MKDS_GIT_EMAIL
	name = $MKDS_GIT_NAME
EOF
echo "$MKDS_VIMRC" > /home/$MKDS_USER/.vimrc
RUNSCRIPT

# network-scripts is deprecated and even static IPs in ifcfg-style config files
# are handled by NetworkManager.
cat <<FIRSTBOOT > $TMP_FIRSTBOOT
systemctl disable firewalld.service
systemctl stop firewalld.service
nmcli connection show
DEVICE=\`nmcli --fields DEVICE connection show --active | tail -n1 | xargs\`
echo "Device: \$DEVICE"
HWADDR=\`ifconfig \$DEVICE | grep ether | awk '{print \$2}'\`
cat <<EOF > /etc/sysconfig/network-scripts/ifcfg-\$DEVICE
NAME="\$DEVICE"
DEVICE="\$DEVICE"
ONBOOT="yes"
TYPE="Ethernet"
HWADDR="\$HWADDR"
BOOTPROTO="none"
IPADDR="$MKDS_STATIC_IP"
NETMASK="$MKDS_NETMASK"
GATEWAY="$MKDS_GATEWAY"
DNS1="$MKDS_NAMESERVER"
EOF
reboot
FIRSTBOOT

virt-builder fedora-30 \
    --size 50G --update --selinux-relabel --format qcow2 \
    --install git,vim,net-tools,bash-completion \
    --output $MKDS_DISK_IMAGE \
    --root-password password:$MKDS_ROOT_PASSWORD \
    --run $TMP_RUNSCRIPT \
    --hostname $MKDS_VM_NAME \
    --firstboot $TMP_FIRSTBOOT
sudo mv $MKDS_DISK_IMAGE /var/lib/libvirt/images
sudo virt-install --import --nographics \
    --machine q35 \
    --vcpus $MKDS_CPUS \
    --ram $MKDS_RAM \
    -w network=$MKDS_VIRT_NETWORK \
    --disk /var/lib/libvirt/images/$MKDS_DISK_IMAGE \
    --name $MKDS_VM_NAME 
