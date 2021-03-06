#!/bin/bash

kernel="$(ls /boot | grep kernel-genkernel | sort -rn | head -n1)"
initramfs="$(ls /boot | grep initramfs-genkernel | sort -rn | head -n1)"

kdenlive="https://files.kde.org/kdenlive/release/$(wget -qO - https://files.kde.org/kdenlive/release/ | grep -Eo kdenlive-[0-9][0-9].[0-9][0-9].[0-9][a-z]-x86_64.appimage | sort -rn | head -n1)"

appimagelauncher_base=https://artifacts.assassinate-you.net/artifactory/AppImageLauncher
appimagelauncher_var1=$(wget -qO - https://artifacts.assassinate-you.net/artifactory/AppImageLauncher | grep -Eo "travis-[0-9]{1,}" | sort -rn | head -n1)
appimagelauncher_var2=$(wget -qO - $appimagelauncher_base/$appimagelauncher_var1 | grep appimagelauncher-lite | grep x86_64 | cut -d "\"" -f2)
appimagelauncher=$appimagelauncher_base/$(wget -qO - https://artifacts.assassinate-you.net/artifactory/AppImageLauncher | grep -Eo "travis-[0-9]{1,}" | sort -rn | head -n1)/$appimagelauncher_var2

#Overlays
layman -L
yes | layman -a awesome
yes | layman -o https://raw.githubusercontent.com/realKennyStrawn93/triggerlinux-overlay/master/triggerlinux-overlay.xml -f -a triggerlinux-overlay

#Ensure that a copy of git-sources exists on the squashfs
emerge sys-kernel/git-sources

#AppImage Daemon
wget -O /usr/bin/appimaged https://github.com/AppImage/appimaged/releases/download/continuous/appimaged-x86_64.AppImage
chmod a+x /usr/bin/appimaged
wget -O /lib/systemd/system/appimaged.service https://raw.githubusercontent.com/AppImage/appimaged/master/resources/appimaged.service
systemctl enable appimaged.service

#AppImage Updater
wget -O /usr/bin/AppImageUpdate https://github.com/AppImage/AppImageUpdate/releases/download/continuous/AppImageUpdate-x86_64.AppImage
chmod a+x /usr/bin/AppImageUpdate
wget -O /usr/share/applications/AppImageUpdate.desktop https://raw.githubusercontent.com/AppImage/AppImageUpdate/rewrite/resources/AppImageUpdate.desktop

#AppImageLauncher
wget -O /usr/bin/appimagelauncher-lite $appimagelauncher
chmod a+x /usr/bin/appimagelauncher-lite
appimagelauncher-lite --install
appimagelauncher-lite --appimage-extract
cp squashfs-root/usr/share/applications/appimagelauncher-lite.desktop /usr/share/applications/appimagelauncher-lite.desktop
for i in $(ls /usr/share/icons); do
  if [ ! -d /usr/share/icons/$i/192x192 ]; then
    mkdir -p /usr/share/icons/$i/192x192/apps
  fi
  cp squashfs-root/usr/share/icons/hicolor/192x192/apps/AppImageLauncher.png /usr/share/icons/$i/192x192/apps/AppImageLauncher.png
done
rm -rf squashfs-root

#Live media hostname
echo "triggerlinux" > /etc/hostname

#Root password
echo -e "triggerlinux\ntriggerlinux" | passwd

#Automatic login
systemctl enable gdm.service
sed -i "3a AutomaticLoginEnable=true" /etc/gdm/custom.conf
sed -i "4a AutomaticLogin=root" /etc/gdm/custom.conf

#Customize Dash-to-Panel
echo -e "[org.gnome.shell.extensions.dash-to-panel]" >> /usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/org.gnome.shell.extensions.dash-to-panel.gschema.override
echo -e "appicon-margin=3" >> /usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/org.gnome.shell.extensions.dash-to-panel.gschema.override
echo -e "hotkeys-overlay-combo='TEMPORARILY'" >> /usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/org.gnome.shell.extensions.dash-to-panel.gschema.override
echo -e "panel-size=40" >> /usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/org.gnome.shell.extensions.dash-to-panel.gschema.override
echo -e "animate-show-apps=false" >> /usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas/org.gnome.shell.extensions.dash-to-panel.gschema.override

#Desktop Background
echo -e "[org.gnome.desktop.background:GNOME]" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "picture-options='stretched'" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "picture-uri='file:///usr/share/backgrounds/gnome/SeaSunset.jpg'" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "primary-color='#ffffff'" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "secondary-color='#000000'" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override

#Lock screen background
echo -e "[org.gnome.desktop.screensaver:GNOME]" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "picture-options='stretched'" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "picture-uri='file:///usr/share/backgrounds/gnome/SeaSunset.jpg'" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "primary-color='#ffffff'" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "secondary-color='#000000'" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override
echo -e "idle-activation-enabled=false" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override

#Enable GNOME Shell extensions by default
echo -e "[org.gnome.shell:GNOME]\nenabled-extensions=['dash-to-panel@jderose9.github.com', 'desktop-icons@csoriano', 'user-theme@gnome-shell-extensions.gcampax.github.com']" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override

#Favorites
libreoffice_writer=libreoffice$(/Applications/LibreOffice.AppImage --version | cut -d' ' -f2 | cut -d\. -f1-2)-writer.desktop
libreoffice_calc=libreoffice$(/Applications/LibreOffice.AppImage --version | cut -d' ' -f2 | cut -d\. -f1-2)-calc.desktop
libreoffice_impress=libreoffice$(/Applications/LibreOffice.AppImage --version | cut -d' ' -f2 | cut -d\. -f1-2)-impress.desktop
libreoffice_math=libreoffice$(/Applications/LibreOffice.AppImage --version | cut -d' ' -f2 | cut -d\. -f1-2)-math.desktop
echo -e "favorite-apps=['org.gnome.Software.desktop', 'dissenter-browser.desktop', 'rhythmbox.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.gedit.desktop', '$libreoffice_writer', '$libreoffice_calc', '$libreoffice_impress', '$libreoffice_math', 'org.kde.kdenlive.desktop', 'isobuild.desktop']" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override

#More window controls than just "Close"
echo -e "[org.gnome.desktop.wm.preferences:GNOME]\nbutton-layout='appmenu:minimize,maximize,close'\n" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override

#Arc Theme + Clock Prefs
echo -e "[org.gnome.desktop.interface:GNOME]\ngtk-theme='Arc'\nicon-theme='Arc'\nclock-show-date=true\nclock-show-seconds=true" >> /usr/share/glib-2.0/schemas/00_org.gnome.shell.gschema.override

#Allow execution of text (.desktop) files in Nautilus by default
echo -e "[org.gnome.nautilus.preferences]" >> /usr/share/glib-2.0/schemas/org.gnome.nautilus.gschema.override
echo -e "executable-text-activation='launch'" >> /usr/share/glib-2.0/schemas/org.gnome.nautilus.gschema.override

#Enable line numbers in gedit by default
echo -e "[org.gnome.gedit.preferences.editor]" >> /usr/share/glib-2.0/schemas/org.gnome.gedit.gschema.override
echo -e "display-line-numbers=true" >> /usr/share/glib-2.0/schemas/org.gnome.gedit.gschema.override

#Recompile Schemas
glib-compile-schemas /usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/schemas
glib-compile-schemas /usr/share/glib-2.0/schemas

#NetworkManager
systemctl enable systemd-resolved.service
systemctl enable NetworkManager.service

#Ensure that printing works out-of-the-box
systemctl enable cups.service

#Get GNOME-Software working
systemctl enable apparmor.service
systemctl enable snapd.apparmor.service
systemctl enable snapd.service

#Make Dissenter work when run as any user, including root
sed -i "s/Exec=.*/Exec=\/usr\/bin\/brave-bin\ \-\-test\-type \-\-no\-sandbox\ \%u/" /usr/share/applications/dissenter-browser.desktop

#Add calamares to root user's desktop as a shortcut
if [ ! -d /root/Desktop ]; then
  mkdir -p /root/Desktop
fi
cp /usr/share/applications/calamares.desktop /root/Desktop/calamares.desktop
chmod a+x /root/Desktop/calamares.desktop
