#!/bin/sh
tmpbg="/tmp/screen_locked.png"
rm "$tmpbg"
scrot "$tmpbg"
magick "$tmpbg" -blur 0x10 "$tmpbg"
i3lock -i "$tmpbg"
