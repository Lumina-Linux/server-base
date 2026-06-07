#!/bin/sh

# 1. Configurar el cursor para que no salga la "X" fea
xsetroot -cursor_name left_ptr

# 2. Arrancar Openbox en el fondo
openbox-session &

# 3. LANZAR EL WRAPPER (No el binario directo)
exec /usr/bin/lumina-calamares
