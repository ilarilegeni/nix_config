#!/bin/sh

language=$1
if [[ $language == "us" ]]; then
  hyprctl keyword input:kb_layout $language
  hyprctl keyword input:kb_variant intl
elif [[ $language == "fr" ]]; then
  hyprctl keyword input:kb_variant ""
  hyprctl keyword input:kb_layout $language
fi
hyprctl keyword input:kb_options caps:escape
