#!/bin/bash

# ==============================================================================
# LUMINA OS SERVER - NATIVE INSTALLER (Hybrid UEFI/BIOS)
# Architecture: Btrfs + systemd-boot/GRUB + Unattended Chroot Infiltration
# ==============================================================================

TITLE="Lumina Server Setup"
LOCALE="en_US.UTF-8"
LOG_FILE="/var/log/lumina_install.log"

# Limpiamos el log anterior si existe
> "$LOG_FILE"

exit_on_cancel() {
    if [ $1 -ne 0 ]; then
        clear
        echo "Installation canceled by the user. Returning to terminal."
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# STEP 1: WELCOME & BOOT MODE DETECTION
# ------------------------------------------------------------------------------
if [ -d "/sys/firmware/efi/efivars" ]; then
    BOOT_MODE="uefi"
    BOOT_MSG="Boot Mode: UEFI (systemd-boot will be installed)"
else
    BOOT_MODE="bios"
    BOOT_MSG="Boot Mode: Legacy BIOS (GRUB will be installed)"
fi

whiptail --title "$TITLE" --msgbox "Welcome to the Lumina Server native installer!\n\n$BOOT_MSG\n\nThis wizard will guide you step by step to configure your infrastructure. Get ready for a fast, clean, and direct installation." 14 65
exit_on_cancel $?

# ------------------------------------------------------------------------------
# STEP 2: NETWORK CONFIGURATION & VALIDATION
# ------------------------------------------------------------------------------
whiptail --title "$TITLE - Network" --infobox "Checking current network status..." 8 50
sleep 2

if ping -c 1 archlinux.org &> /dev/null; then
    NET_STATUS="Internet connection DETECTED (Likely DHCP)."
else
    NET_STATUS="NO internet connection detected."
fi

whiptail --title "$TITLE - Network Configuration" --yesno "Status: $NET_STATUS\n\nDo you want to manually configure the network now?\n(Highly recommended to set a Static IP for servers)" 12 65

if [ $? -eq 0 ]; then
    nmtui
fi

whiptail --title "$TITLE - Network" --infobox "Validating connection for package download..." 8 50
sleep 1

if ! ping -c 1 archlinux.org &> /dev/null; then
    whiptail --title "$TITLE - Critical Error" --msgbox "No internet connection available. Pacstrap cannot download packages.\n\nThe installation will now abort." 12 50
    clear
    exit 1
fi

# ------------------------------------------------------------------------------
# STEP 3: KEYBOARD SELECTION
# ------------------------------------------------------------------------------
KEYMAP=$(whiptail --title "$TITLE - Keyboard" --menu "Select your physical keyboard layout:" 15 60 4 \
    "us" "English (US)" \
    "la-latin1" "Spanish (Latin America)" \
    "es" "Spanish (Spain)" \
    3>&1 1>&2 2>&3)
exit_on_cancel $?

loadkeys $KEYMAP

# ------------------------------------------------------------------------------
# STEP 3.5: FEATURE SELECTION (Snapshots)
# ------------------------------------------------------------------------------
if whiptail --title "Lumina Server - Advanced Features" --yesno \
   "Would you like to enable BTRFS Snapshots?" 10 60; then
    ENABLE_SNAPSHOTS="true"
else
    ENABLE_SNAPSHOTS="false"
fi

# ------------------------------------------------------------------------------
# STEP 4: SYSTEM IDENTITY
# ------------------------------------------------------------------------------
HOSTNAME=$(whiptail --title "$TITLE - Hostname" --inputbox "Enter the server hostname:" 10 50 "lumina-server" 3>&1 1>&2 2>&3)
exit_on_cancel $?

USERNAME=$(whiptail --title "$TITLE - User" --inputbox "Enter the administrator username:" 10 50 "" 3>&1 1>&2 2>&3)
exit_on_cancel $?

while true; do
    USER_PASS1=$(whiptail --title "$TITLE - Password" --passwordbox "Enter the password for $USERNAME:" 10 50 3>&1 1>&2 2>&3)
    exit_on_cancel $?
    USER_PASS2=$(whiptail --title "$TITLE - Confirm" --passwordbox "Confirm the password:" 10 50 3>&1 1>&2 2>&3)
    exit_on_cancel $?

    if [ "$USER_PASS1" == "$USER_PASS2" ]; then
        break
    else
        whiptail --title "Error" --msgbox "Passwords do not match. Please try again." 10 50
    fi
done

# ------------------------------------------------------------------------------
# STEP 5: DISK SELECTION
# ------------------------------------------------------------------------------
declare -a DISK_ARRAY
while read -r name size model; do
    DISK_ARRAY+=("/dev/$name" "$size - $model")
done < <(lsblk -d -n -e 7,11 -o NAME,SIZE,MODEL)

TARGET_DISK=$(whiptail --title "$TITLE - Disk Selection" --menu "Select the target drive for Lumina OS (WARNING: ALL DATA WILL BE ERASED):" 15 65 5 "${DISK_ARRAY[@]}" 3>&1 1>&2 2>&3)
exit_on_cancel $?

whiptail --title "$TITLE - WARNING" --yesno "You selected $TARGET_DISK.\n\nAre you ABSOLUTELY sure? This will wipe the entire drive without recovery." 10 50
exit_on_cancel $?

whiptail --title "$TITLE - Summary" --yesno "Configuration complete. Review your details:\n\nBoot Mode: $BOOT_MODE\nKeyboard: $KEYMAP\nHostname: $HOSTNAME\nUser: $USERNAME\nDisk: $TARGET_DISK\n\nDo you want to begin the unattended installation?" 17 65
exit_on_cancel $?

# ==============================================================================
# UNATTENDED INSTALLATION PHASE (PROGRESS BAR)
# ==============================================================================

# Encapsulating the noisy logic inside whiptail --gauge
{
    echo "XXX"
    echo "5"
    echo "Initiating disk partition scheme..."
    echo "XXX"

    sgdisk -Z "$TARGET_DISK" >> "$LOG_FILE" 2>&1

    if [ "$BOOT_MODE" == "uefi" ]; then
        sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI System" "$TARGET_DISK" >> "$LOG_FILE" 2>&1
    else
        sgdisk -n 1:0:+2M -t 1:ef02 -c 1:"BIOS Boot" "$TARGET_DISK" >> "$LOG_FILE" 2>&1
    fi

    sgdisk -n 2:0:0 -t 2:8300 -c 2:"Lumina Root" "$TARGET_DISK" >> "$LOG_FILE" 2>&1

    if [[ "$TARGET_DISK" == *"nvme"* ]] || [[ "$TARGET_DISK" == *"loop"* ]]; then
        PART_SUFFIX="p"
    else
        PART_SUFFIX=""
    fi
    BOOT_PART="${TARGET_DISK}${PART_SUFFIX}1"
    ROOT_PART="${TARGET_DISK}${PART_SUFFIX}2"

    echo "XXX"
    echo "15"
    echo "Formatting Btrfs and creating subvolumes..."
    echo "XXX"

    if [ "$BOOT_MODE" == "uefi" ]; then
        mkfs.fat -F32 "$BOOT_PART" >> "$LOG_FILE" 2>&1
    fi

    mkfs.btrfs -f -L LUMINA "$ROOT_PART" >> "$LOG_FILE" 2>&1

    mount "$ROOT_PART" /mnt >> "$LOG_FILE" 2>&1
    btrfs subvolume create /mnt/@ >> "$LOG_FILE" 2>&1
    btrfs subvolume create /mnt/@home >> "$LOG_FILE" 2>&1
    btrfs subvolume create /mnt/@log >> "$LOG_FILE" 2>&1
    btrfs subvolume create /mnt/@pkg >> "$LOG_FILE" 2>&1

    if [ "$ENABLE_SNAPSHOTS" == "true" ]; then
        btrfs subvolume create /mnt/@snapshots >> "$LOG_FILE" 2>&1
    fi

    umount /mnt >> "$LOG_FILE" 2>&1

    echo "XXX"
    echo "25"
    echo "Mounting filesystems with optimized flags (ZSTD)..."
    echo "XXX"

    BTRFS_OPTS="defaults,noatime,compress=zstd,space_cache=v2"
    mount -o "$BTRFS_OPTS",subvol=@ "$ROOT_PART" /mnt >> "$LOG_FILE" 2>&1
    mkdir -p /mnt/{boot,home,var/log,var/cache/pacman/pkg}
    mount -o "$BTRFS_OPTS",subvol=@home "$ROOT_PART" /mnt/home >> "$LOG_FILE" 2>&1
    mount -o "$BTRFS_OPTS",subvol=@log "$ROOT_PART" /mnt/var/log >> "$LOG_FILE" 2>&1
    mount -o "$BTRFS_OPTS",subvol=@pkg "$ROOT_PART" /mnt/var/cache/pacman/pkg >> "$LOG_FILE" 2>&1

    if [ "$ENABLE_SNAPSHOTS" == "true" ]; then
        mkdir -p /mnt/.snapshots
        mount -o "$BTRFS_OPTS",subvol=@snapshots "$ROOT_PART" /mnt/.snapshots >> "$LOG_FILE" 2>&1
    fi

    if [ "$BOOT_MODE" == "uefi" ]; then
        mount "$BOOT_PART" /mnt/boot >> "$LOG_FILE" 2>&1
    fi

    echo "XXX"
    echo "35"
    echo "Syncing repositories and installing base system..."
    echo "Grab a coffee, this will take a moment..."
    echo "XXX"

    pacman-key --populate lumina >> "$LOG_FILE" 2>&1
    pacman-key --lsign-key admin@luminalinux.org >> "$LOG_FILE" 2>&1

    CORE_PACKAGES="base linux linux-firmware btrfs-progs networkmanager nano sudo"
    if [ "$BOOT_MODE" == "bios" ]; then
        CORE_PACKAGES="$CORE_PACKAGES grub"
    fi

    pacstrap /mnt $CORE_PACKAGES $EXTRA_PACKAGES >> "$LOG_FILE" 2>&1

    echo "XXX"
    echo "65"
    echo "Generating fstab and creating Pacman configuration..."
    echo "XXX"

    genfstab -U /mnt >> /mnt/etc/fstab 2>> "$LOG_FILE"

    cp /etc/pacman.conf /mnt/etc/pacman.conf
    mkdir -p /mnt/usr/share/pacman/keyrings/
    cp -a /usr/share/pacman/keyrings/* /mnt/usr/share/pacman/keyrings/
    cp -a /etc/pacman.d/* /mnt/etc/pacman.d/

    if [ -d "/mnt/etc/pacman.d/gnupg" ]; then
        chown -R root:root /mnt/etc/pacman.d/gnupg
        find /mnt/etc/pacman.d/gnupg -type d -exec chmod 700 {} +
        find /mnt/etc/pacman.d/gnupg -type f -exec chmod 600 {} +
    fi

    if [ -d "/mnt/usr/share/pacman/keyrings" ]; then
        chown -R root:root /mnt/usr/share/pacman/keyrings
        chmod 644 /mnt/usr/share/pacman/keyrings/*
    fi

    echo "XXX"
    echo "75"
    echo "Configuring role manager into the new system..."
    echo "XXX"

    mkdir -p /mnt/usr/local/bin
    cp /usr/local/bin/roleman /mnt/usr/local/bin/roleman >> "$LOG_FILE" 2>&1
    chmod +x /mnt/usr/local/bin/roleman

    ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")

    cat << EOF > /mnt/root/chroot-infiltrator.sh
#!/bin/bash

echo "$HOSTNAME" > /etc/hostname
rm -f /var/lib/pacman/db.lck
rm -rf /etc/pacman.d/gnupg

pacman-key --init
pacman-key --populate archlinux
pacman-key --populate lumina
pacman-key --lsign-key 093B74E82FCA45014329D8B1FE2080D27FBE66D8

cat << 'EOF_OS' > /etc/os-release
NAME="Lumina Server"
ID="lumina"
ID_LIKE="arch"
PRETTY_NAME="Lumina Server"
ANSI_COLOR="1;34"
HOME_URL="https://luminalinux.org"
EOF_OS

cat << EOF_MOTD > /etc/profile.d/motd.sh
#!/bin/bash
echo -e "\e[1;34m"
echo "======================================================="
echo "               L U M I N A   S E R V E R               "
echo "======================================================="
echo -e "\e[0m"
echo -e " Kernel: \e[1;32m\$(uname -r)\e[0m"
echo -e " Host:   \e[1;32m\$(hostname)\e[0m"
echo "======================================================="
echo""
echo -e "Type: roleman to run the Lumina Server Role Manager"
echo""
EOF_MOTD
chmod +x /etc/profile.d/motd.sh
# ==========================================

ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

systemctl enable NetworkManager

echo "root:$USER_PASS1" | chpasswd
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$USER_PASS1" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

if [ "$ENABLE_SNAPSHOTS" == "true" ]; then
    umount -l /.snapshots 2>/dev/null
    rm -rf /.snapshots
    snapper -c root create-config /
    mkdir -p /.snapshots
    chmod 750 /.snapshots
fi

if [ "$BOOT_MODE" == "uefi" ]; then
    bootctl install
    cat << BOOTCONF > /boot/loader/loader.conf
default lumina.conf
timeout 3
console-mode max
editor no
BOOTCONF
    cat << ENTRY > /boot/loader/entries/lumina.conf
title   Lumina Server
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$ROOT_UUID rootflags=subvol=@ rw quiet
ENTRY
else
    grub-install --target=i386-pc "$TARGET_DISK"
    echo 'GRUB_DISTRIBUTOR="Lumina Server"' >> /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
fi

rm -f /root/chroot-infiltrator.sh
EOF

    chmod +x /mnt/root/chroot-infiltrator.sh

    echo "XXX"
    echo "85"
    echo "Chroot infiltration in progress. Forging system identity..."
    echo "XXX"

    arch-chroot /mnt /root/chroot-infiltrator.sh >> "$LOG_FILE" 2>&1

    echo "XXX"
    echo "100"
    echo "Deployment completed successfully!"
    echo "XXX"
    sleep 2

} | whiptail --title "Lumina Server Installer" --gauge "\nInitiating installation sequence..." 9 70 0

# ==============================================================================
# STEP 7.5: INTERACTIVE ROLE DEPLOYMENT
# ==============================================================================
clear
if [ -x /mnt/usr/local/bin/roleman ]; then
    arch-chroot /mnt /usr/local/bin/roleman
else
    echo "    [!] roleman not found in the new system."
    sleep 3
fi

# ------------------------------------------------------------------------------
# STEP 8: FINALIZATION
# ------------------------------------------------------------------------------
umount -R /mnt >> "$LOG_FILE" 2>&1

clear
whiptail --title "Installation completed!" --msgbox "LUMINA SERVER INSTALLATION IS COMPLETE!\n\nReview any potential warnings in /var/log/lumina_install.log if needed.\n\nRemove the installation media and reboot the server." 12 60
