#!/bin/sh

set -euo pipefail

# Liste des profils disponibles (une entrée par ligne)
mapfile -t avail < <(powerprofilesctl list | sed -n 's/^\s*\**\s*\([a-z-]\+\):.*/\1/p')

# Menu rofi (liste verticale)
choice="$(printf '%s\n' "${avail[@]}" | rofi -dmenu -p 'Profil énergie' -l 5 -i)"

# Appliquer le choix
[ -n "${choice:-}" ] && powerprofilesctl set "$choice"
