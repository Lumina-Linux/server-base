#!/bin/bash
# =====================================================================
# Lumina OS - Script de Post-Instalación (Fase Inicial de Snapper)
# =====================================================================

echo "Iniciando configuración avanzada de Snapper y Btrfs..."

# ---------------------------------------------------------------------
# STEP 1: Crear el subvolumen @snapshots que Calamares omitió
# ---------------------------------------------------------------------
echo "Corrigiendo omisión de Calamares: Creando subvolumen @snapshots..."
mkdir -p /tmp/btrfs_root
UUID_RAIZ=$(findmnt -no UUID /)

# Montamos el nivel 5 de Btrfs (el disco crudo) para inyectar el subvolumen
mount -o subvolid=5 /dev/disk/by-uuid/${UUID_RAIZ} /tmp/btrfs_root
if [ ! -d "/tmp/btrfs_root/@snapshots" ]; then
    btrfs subvolume create /tmp/btrfs_root/@snapshots
fi
umount /tmp/btrfs_root
rm -rf /tmp/btrfs_root

# ---------------------------------------------------------------------
# STEP 2: Forzar la creación de la configuración de Snapper en /etc
# ---------------------------------------------------------------------
echo "Inicializando archivo de configuración de Snapper..."
# Limpieza absoluta de la raíz. No puede haber NADA en /.snapshots
umount -l /.snapshots 2>/dev/null
rm -rf /.snapshots

# Al estar la raíz limpia, Snapper crea con éxito /etc/snapper/configs/root
snapper -c root create-config /

# ---------------------------------------------------------------------
# STEP 3: Purga del subvolumen basura de Snapper e inyección en fstab
# ---------------------------------------------------------------------
echo "Vinculando subvolumen @snapshots real al sistema..."
umount -l /.snapshots 2>/dev/null
btrfs subvolume delete /.snapshots 2>/dev/null || rm -rf /.snapshots

# Inyectamos la persistencia en el fstab
if ! grep -q "@snapshots" /etc/fstab; then
    echo "UUID=${UUID_RAIZ} /.snapshots btrfs subvol=@snapshots,defaults,noatime,compress=zstd 0 0" >> /etc/fstab
fi

mkdir -p /.snapshots
mount /.snapshots
chmod 750 /.snapshots

# LA LÍNEA MAESTRA: Seteamos el subvolumen por defecto al ID 5
# Esto repara el divorcio de Calamares y habilita el rollback automático en terminal
btrfs subvolume set-default 5 /

echo "¡Estructura de Snapper y Btrfs automatizada con éxito!"

# ---------------------------------------------------------------------
# STEP 4: PROTOCOLO DE AUTODESTRUCCIÓN (Fin del peligro)
# ---------------------------------------------------------------------
echo "Ejecución única completada. Eliminando rastro del script..."

# 1. Deshabilitamos el servicio para que systemd jamás intente buscarlo en el próximo boot
systemctl disable lumina-postinstall.service 2>/dev/null

# 2. Volamos el archivo del servicio de la raíz para que no quede basura en el sistema
rm -f /etc/systemd/system/lumina-postinstall.service

# 3. Recargamos el demonio de systemd para limpiar la memoria RAM en caliente
systemctl daemon-reload

# 4. El script se vuela a sí mismo del disco duro
rm -f "$0"

echo "Protocolo kamikaze finalizado. Lumina OS es ahora segura."
