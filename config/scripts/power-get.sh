#!/bin/sh

profile=$(powerprofilesctl get)

if [ $profile = "performance" ]; then
  echo "󰓅"
elif [ $profile = "balanced" ]; then
  echo "󰾅"
elif [ $profile = "power-saver" ]; then
  echo "󰾆"
else
  echo "󰾅"
fi
