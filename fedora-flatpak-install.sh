#!/usr/bin/env bash

# 251023
# - adding gnome-terminal
# 251021
# - installation of wheel/sudo file added about line 21-28
# 251010-00

##########################################################################################
# flatpak based installation
##########################################################################################

# remove flatpaks
#  org.freedesktop.Sdk.Extension.dotnet

for app in \
       com.brave.Browser \
       org.audacityteam.Audacity \
       com.jetbrains.GoLand \
       com.jetbrains.DataGrip \
       com.jetbrains.RubyMine \
       com.jetbrains.RustRover \
       com.jetbrains.IntelliJ-IDEA-Ultimate \
       md.obsidian.Obsidian \
       org.gnome.GHex \
       com.ktechpit.whatsie \
       com.visualstudio.code
do
   echo Working on $app...
   sudo flatpak install --or-update -y --noninteractive flathub $app
done


##########################################################################################
# EOF
