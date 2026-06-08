#!/bin/bash
# =====================================================================
# Lumina OS - Script de Post-Instalación (Fase Final de Blindaje)
# =====================================================================

echo "Iniciando configuración avanzada de Snapper, Btrfs..."

# ---------------------------------------------------------------------
# STEP 1: Crear el subvolumen @snapshots que Calamares omitió
# ---------------------------------------------------------------------
echo "Corrigiendo omisión de Calamares: Creando subvolumen @snapshots..."
mkdir -p /tmp/btrfs_root
UUID_RAIZ=$(findmnt -no UUID /)

mount -o subvolid=5 /dev/disk/by-uuid/${UUID_RAIZ} /tmp/btrfs_root
if [ ! -d "/tmp/btrfs_root/@snapshots" ]; then
    btrfs subvolume create /tmp/btrfs_root/@snapshots
fi
umount /tmp/btrfs_root
rm -rf /tmp/btrfs_root

# ---------------------------------------------------------------------
# STEP 2: Forzar la configuración de Snapper en /etc
# ---------------------------------------------------------------------
echo "Inicializando configuración de Snapper..."
umount -l /.snapshots 2>/dev/null
rm -rf /.snapshots
snapper -c root create-config /

# ---------------------------------------------------------------------
# STEP 3: Purga del subvolumen basura e inyección en fstab
# ---------------------------------------------------------------------
echo "Vinculando subvolumen @snapshots real..."
umount -l /.snapshots 2>/dev/null
btrfs subvolume delete /.snapshots 2>/dev/null || rm -rf /.snapshots

if ! grep -q "@snapshots" /etc/fstab; then
    echo "UUID=${UUID_RAIZ} /.snapshots btrfs subvol=@snapshots,defaults,noatime,compress=zstd 0 0" >> /etc/fstab
fi

mkdir -p /.snapshots
mount /.snapshots
chmod 750 /.snapshots
btrfs subvolume set-default 5 /

# ---------------------------------------------------------------------
# STEP 4: Instalación final de configuración
# ---------------------------------------------------------------------
echo "Sincronizando repositorios e instalando configuración del sistema..."
pacman -Sy --noconfirm lumina-keyring lumina-system-config

# ---------------------------------------------------------------------
# STEP 5: PROTOCOLO DE AUTODESTRUCCIÓN
# ---------------------------------------------------------------------
echo "Ejecución única completada. Limpiando..."
systemctl disable lumina-postinstall.service 2>/dev/null
rm -f /etc/systemd/system/lumina-postinstall.service
systemctl daemon-reload
rm -f "$0"

echo "Protocolo kamikaze finalizado. Lumina OS es ahora segura."
