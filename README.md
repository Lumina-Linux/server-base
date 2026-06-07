Lumina Linux (Server Base) English | Español

English

Lumina OS is a minimalist, independent distribution based on Arch Linux, architected for users who demand high performance, stability, and absolute control over their environment. Built with an uncompromised commitment to engineering integrity, it delivers a curated rolling-release system completely free of corporate telemetry, tracking, or pre-installed bloatware.

This repository contains the official production templates, deployment scripts, and configuration manifests utilizing the archiso framework.

🛠️ Core Architecture & Technical Specifications Base Core: Arch Linux (Curated Rolling Release).

Kernel: Linux Kernel LS / HARDENDED

Package Management: Native pacman with strict package validation criteria.

Target Focus: Cloud engineers, system administrators, and advanced users who require a lean, scalable base to design their ideal workstation.

📂 Repository Structure /airootfs - Root filesystem overlay, configuration profiles, and environmental permissions.

/packages.x86_64 - Manifest of core system packages compiled for the live environment and base installation.

/pacman.conf - Custom package manager configuration optimizing repository mirrors and security keys.

profiledef.sh - Official build definition script managing ISO metadata and system execution rights.

🚀 Deployment & Installation To flash the production ISO directly to a raw storage block (replace /dev/sdX with your target drive node):

sudo dd bs=4M if=lumina-server-x86_64.iso of=/dev/sdX status=progress oflag=sync

Español

Lumina OS is a minimalist, independent distribution based on Arch Linux, architected for users who demand high performance, stability, and absolute control over their environment. Built with an uncompromised commitment to engineering integrity, it delivers a curated rolling-release system completely free of corporate telemetry, tracking, or pre-installed bloatware.

Este repositorio contiene las plantillas oficiales de producción, scripts de despliegue y manifiestos de configuración basados en el framework archiso.

🛠️ Arquitectura Central y Especificaciones Técnicas Núcleo Base: Arch Linux (Rolling Release curado).

Kernel: Linux Kernel LTS / HARDENDED

Gestor de Paquetes: pacman nativo con criterios estrictos de validación de repositorios.

Perfil de Usuario: Ingenieros de nube, administradores de sistemas y usuarios avanzados que requieren una base limpia y escalable para diseñar su estación de trabajo ideal.

📂 Estructura del Repositorio /airootfs - Capa del sistema de archivos raíz, perfiles de configuración y permisos de entorno.

/packages.x86_64 - Manifiesto de paquetes del sistema base compilados para el entorno en vivo.

/pacman.conf - Configuración personalizada del gestor de paquetes para optimizar réplicas de repositorios y llaves de seguridad.

profiledef.sh - Script oficial de definición de compilación que gestiona los metadatos de la ISO y derechos de ejecución.

🚀 Despliegue e Instalación Para escribir la ISO de producción directamente en un bloque de almacenamiento (reemplaza /dev/sdX con el nodo de tu unidad destino):

sudo dd bs=4M if=lumina-serer-x86_64.iso of=/dev/sdX status=progress oflag=sync
