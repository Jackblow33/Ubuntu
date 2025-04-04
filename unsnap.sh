#!/bin/bash

#Execute as root
#Remove Snap Packages from Ubuntu 24.04-25.04 & install firefox as deb
#Source https://kskroyal.com/remove-snap-packages-from-ubuntu/

#VARIABLE
TIMESTAMP=`date +%Y%m%d.%R`

#VARIABLE                           #snap packages to be removed
PKGS=(
        'firefox'                    # Web browser
        'gtk-common-themes'          # ....
        'gnome-42-2204'              # ....
        'snapd-desktop-integration'  # ....
        'snap-store'                 # ....
        'firmware-updater'           # ....
        'bare'                       # ....
        'desktop-security-center'    # ....
        'prompting-client'           # ....

)

#fonction
timer_start()
{
BEGIN=$(date +%s)
}

#fonction
timer_stop()
{
    NOW=$(date +%s)
    let DIFF=$(($NOW - $BEGIN))
    let MINS=$(($DIFF / 60))
    let SECS=$(($DIFF % 60))
    echo Time elapsed: $MINS:`printf %02d $SECS`
}

# Make sure only root can run the script -----------#
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "Before removing snaps packages from Ubuntu, ensure there is no app running in the background except the terminal [enter]"; read enterKey
apt update && sudo apt upgrade -y
timer_start

#UnSnap
for PKG in "${PKGS[@]}"; do
    echo "UNSnapping: ${PKG}"
    snap remove "$PKG"
done

#  delete core22 snapd after every other snaps
snap remove core22 snapd

#  Remove Snap Daemon
systemctl stop snapd
systemctl disable snapd

#  Prevents the snapd service from being started or enabled on your system
systemctl mask snapd

#  Purge snapd using apt
apt purge snapd -y

#  Type the below command to mark the snapd package as being held, which prevents it from being upgraded automatically by the apt package manager
apt-mark hold snapd

#  Delete the snap package directories
rm -rf ~/snap
rm -rf /snap
rm -rf /var/snap
rm -rf /var/lib/snapd

#  Then copy create & add lines to /etc/apt/preferences.d/nosnap.pref
mv /etc/apt/preferences.d/nosnap.pref /etc/apt/preferences.d/nosnap.pref_$TIMESTAMP
touch /etc/apt/preferences.d/nosnap.pref
chmod +rw /etc/apt/preferences.d/nosnap.pref   #read write permission
echo  "Package: snapd" >> /etc/apt/preferences.d/nosnap.pref
echo "Pin: release a=*" >> /etc/apt/preferences.d/nosnap.pref
echo "Pin-Priority: -10" >> /etc/apt/preferences.d/nosnap.pref
echo "[enter]"; read enterKey
#  Prevent Snap from reinstalling
nano /etc/apt/preferences.d/nosnap.pref
#chmod -w /etc/apt/preferences.d

#Installing Firefox as DEB #########
apt update

#  command to create an apt keyring
install -d -m 0755 /etc/apt/keyrings

#  Mozilla apt repository signing key
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null

#  Mozilla signing keys to the apt source list
echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null

#  Configure apt to prioritize packages from the Mozilla repository
echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla

#  Update the apt source list and install the Firefox deb package
apt-get update && apt-get install firefox

#  Gnome App Store
apt install --install-suggests gnome-software -y
timer_stop

echo "Reboot now. Press [enter]"; read enterKey
reboot
