#!/bin/sh

mode=$(makoctl mode)
tog=0

if [ "$1" = "toggle" ]; then
  tog=1
fi
if [ "$mode" = "do-not-disturb" ]; then
  if [ $tog -eq 0 ]; then
    echo "⏾"
  else
    makoctl mode -s default
  fi
else
  if [ $tog -eq 0 ]; then
    echo "📢"
  else
    makoctl mode -s do-not-disturb
  fi
fi
