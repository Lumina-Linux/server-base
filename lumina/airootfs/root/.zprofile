if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    # Lanzamos el entorno gráfico directo al grano
    exec startx
fi
