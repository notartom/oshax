#!/bin/sh

OPTIND=1

default_user="artom"
default_password="password"
tmp_runscript="/tmp/mkdevstack.runscript.sh"

while getopts "u:p:r:o:" opt; do
    case "$opt" in
    u)
        user="$OPTARG"
        ;;
    p)
        user_password="$OPTARG"
        ;;
    r)
        root_password="$OPTARG"
        ;;
    o)
        output_file="$OPTARG"
        ;;
    esac
done

if [ -z "$user" ]; then
    user=$default_user
fi
if [ -z "$user_password" ]; then
    user_password=$default_password
fi
if [ -z "$root_password" ]; then
    root_password=$default_password
fi
if [ -z "$output_file" ]; then
    echo "Missing -o <output file> argument."
    exit
fi

# TODO Find a way to not hardcode the pubkey
cat <<EOF > $tmp_runscript
password='`openssl passwd -6 $user_password`'
useradd -G wheel -p "\$password" -m $user
ssh_dir="/home/$user/.ssh"
mkdir \$ssh_dir
chown $user:$user \$ssh_dir
chmod 700 \$ssh_dir
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDWOmZ6xGuZlDxxpWWuQQZ2OzBP+kz6DPfwLFOcWtMm1El7W28rMOcEOE9htSRi3k22nBar/IyDuBxqPcAgt05AUB50cVRtj5/kj0ReEERIzOQKxH5VSATKiZ/ST8OTM9jj7ANvDM1LSZYWhzRCncg2bTLlHK7nKeRQfv3frRVG65dcB2Ks9gr40ht8lq9W5M35mnaMrNTPBX71oAOMQlFtBx0uqtSBPf8mxf5vz+6DmE5ptbEYK9xEW1FHj5f3h1RiPkRQs2LetH5u1RE3nZoCK/aqkf914IGIELb2M9F8Cd/ks0a/TwGDt+hXatybsmHIQNSqT27rQAbcUrlyYpav artom@zoe" > \$ssh_dir/authorized_keys
EOF

virt-builder -o $output_file --size 50G --update --selinux-relabel \
    --format qcow2 --root-password password:$root_password \
    --install git,vim \
    --run $tmp_runscript \
    fedora-30
