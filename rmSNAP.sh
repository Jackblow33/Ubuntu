#!/bin/bash

#Execute as root
#Remove Snap Packages from Ubuntu 24.04-25.04 install firefox as deb
#Source https://kskroyal.com/remove-snap-packages-from-ubuntu/

#variable
TIMESTAMP=`date +%Y%m%d.%R`

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
sudo apt update && sudo apt upgrade -y
timer_start
sudo snap remove firefox
sudo snap remove gtk-common-themes
sudo snap remove gnome-42-2204
sudo snap remove snapd-desktop-integration
sudo snap remove snap-store
sudo snap remove firmware-updater
sudo snap remove bare  
sudo snap remove desktop-security-center
sudo snap remove prompting-client

#  delete core snap
sudo snap remove core22
sudo snap remove snapd
#echo "[enter]"; read enterKey

#  Once everything is deleted, type snap list and you will see no snaps are installed
snap list
#echo "[enter]"; read enterKey


#  Remove Snap Daemon
sudo systemctl stop snapd
sudo systemctl disable snapd

#  Prevents the snapd service from being started or enabled on your system
sudo systemctl mask snapd

#  Purge snapd using apt
sudo apt purge snapd -y

#  Type the below command to mark the snapd package as being held, which prevents it from being upgraded automatically by the apt package manager
sudo apt-mark hold snapd

#  Delete the snap package directories
sudo rm -rf ~/snap
sudo rm -rf /snap
sudo rm -rf /var/snap
sudo rm -rf /var/lib/snapd

#  Then copy create & add lines to /etc/apt/preferences.d/nosnap.pref
mv /etc/apt/preferences.d/nosnap.pref /etc/apt/preferences.d/nosnap.pref_$TIMESTAMP
sudo touch /etc/apt/preferences.d/nosnap.pref
sudo chmod +rw /etc/apt/preferences.d/nosnap.pref   #read write permission
sudo echo  "Package: snapd" >> /etc/apt/preferences.d/nosnap.pref
sudo echo "Pin: release a=*" >> /etc/apt/preferences.d/nosnap.pref
sudo echo "Pin-Priority: -10" >> /etc/apt/preferences.d/nosnap.pref
echo "[enter]"; read enterKey
#  Prevent Snap from reinstalling
sudo nano /etc/apt/preferences.d/nosnap.pref
sudo chmod -w /etc/apt/preferences.d

#Installing Firefox as DEB
#echo "[Installing Firefox as ,deb enter]"; read enterKey
sudo apt update

#  command to create an apt keyring
sudo install -d -m 0755 /etc/apt/keyrings

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
sudo apt-get update && sudo apt-get install firefox

#  Gnome App Store
sudo apt install --install-suggests gnome-software -y
timer_stop

echo "Reboot now [enter]"; read enterKey
sudo reboot

