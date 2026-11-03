#!/bin/sh
# Usage: sh tools/build_dashboard_gif.sh before.png after.png
# Generated artwork is kept in the imagegen output folder; only final assets ship.
set -eu
mkdir -p assets/dashboard
makeup_mix="if(lt(T,1.2),0,if(lt(T,3.8),(T-1.2)/2.6,if(lt(T,6.2),1,(8-T)/1.8)))"
face_mask="max(0,min(1,(1-pow((X-540)/330,2)-pow((Y-680)/320,2))*4))"
ffmpeg -hide_banner -loglevel error -y \
  -loop 1 -framerate 10 -i "$1" -loop 1 -framerate 10 -i "$2" \
  -filter_complex "[0:v]scale=1080:1350:force_original_aspect_ratio=increase,crop=1080:1350,format=rgb24[b];[1:v]scale=1080:1350:force_original_aspect_ratio=increase,crop=1080:1350,format=rgb24[a];[b][a]blend=all_expr='A*(1-($makeup_mix)*($face_mask))+B*($makeup_mix)*($face_mask)',trim=duration=8,split[p][v];[p]palettegen=max_colors=192:stats_mode=diff[pal];[v][pal]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle" \
  -loop 0 assets/dashboard/makeup-preview-hd.gif
ffmpeg -hide_banner -loglevel error -y -i assets/dashboard/makeup-preview-hd.gif \
  -ss 4.5 -frames:v 1 -q:v 3 assets/dashboard/makeup-poster.jpg
