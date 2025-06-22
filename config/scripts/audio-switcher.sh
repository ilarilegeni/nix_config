#!/bin/sh

# Récupère toutes les sorties audio (sinks), exclut les sources/micros et lignes de volume
outputs=$(pactl list short sinks | awk '{print $2}')

# Vérifie si des sorties ont été détectées
if [ -z "$outputs" ]; then
    notify-send "Erreur" "Aucune sortie audio trouvée." -u critical
    exit 1
fi

# Affiche le menu (wofi, rofi ou fzf)
selection=$(echo "$outputs" | rofi -dmenu -p "Choisir sortie audio")

# Vérifie que l'utilisateur a bien sélectionné quelque chose
if [ -z "$selection" ]; then
    notify-send "Changement annulé"
    exit 0
fi

# Si l'utilisateur a sélectionné un sink
if [ -n "$selection" ]; then
    # Récupère l'index du sink choisi
    sink_index=$(pactl list short sinks | grep "$selection" | awk '{print $1}')
    echo $sink_index

    # Change le sink par défaut
    pactl set-default-sink "$sink_index"

    # Redirige les flux audio en cours vers le nouveau sink
    for input in $(pactl list short sink-inputs | awk '{print $1}'); do
        pactl move-sink-input "$input" "$sink_index"
    done

    notify-send "Sortie audio changée" "Nouvelle sortie : $selection"
else
    notify-send "Changement annulé" "Aucune sortie sélectionnée"
fi
