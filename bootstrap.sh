#! /bin/sh

## General setup
# update
sudo apt update -y
sudo apt full-upgrade -y
sudo apt clean -y
sudo rpi-update -y
# custom boot
cp config.txt /boot
# setup device name
# setup wifi

cp check-services-status-led.py /usr/local/bin
cp check-services-status-led.service /etc/systemd/system
sudo systemctl enable check-services-status-led.service

cp listen-for-shutdown.service /etc/systemd/system
cp listen-for-shutdown.py /usr/local/bin
sudo systemctl enable listen-for-shutdown.service

## shairport for AirPlay
# TODO try docker image with detached mode instead of apt + git clone + systemctl	
sudo apt install --no-install-recommends build-essential git autoconf automake libtool \
    libpopt-dev libconfig-dev libasound2-dev avahi-daemon libavahi-client-dev libssl-dev libsoxr-dev \
    libplist-dev libsodium-dev libavutil-dev libavcodec-dev libavformat-dev uuid-dev libgcrypt-dev xxd
git clone https://github.com/mikebrady/shairport-sync.git
cd shairport-sync
autoreconf -fi
./configure --sysconfdir=/etc --with-alsa \
  --with-soxr --with-avahi --with-ssl=openssl --with-systemd --with-airplay-2
make
sudo make install
shairport-sync -v
cp shairport-sync.conf /etc
#cp shairport-sync.service /lib/systemd/system
sudo systemctl enable shairport-sync

## rapspotify for Spotify Connect
# /!\ seems like ARMv6 (Raspberry Pi 1 & Zero v1 is no longer supported after 0.31.8.1) /!\
# wget https://github.com/dtcooper/raspotify/releases/download/0.31.8.1/raspotify_0.31.8.1.librespot.v0.3.1-54-gf4be9bb_armhf.deb
# sudo apt install raspotify_0.31.8.1.librespot.v0.3.1-54-gf4be9bb_armhf.deb
sudo apt-get -y install curl && curl -sL https://dtcooper.github.io/raspotify/install.sh | sh
cp raspotify /etc/default
cp raspotify.service /lib/systemd/system
sudo systemctl enable raspotify
