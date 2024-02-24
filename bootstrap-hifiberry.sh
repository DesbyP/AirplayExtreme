#! /bin/sh

ln -sfn $PWD/check-services-status-led.py /usr/bin
ln -sfn $PWD/listen-for-shutdown.py /usr/bin
cp listen-for-shutdown.service /etc/systemd/system/
cp check-services-status-led.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable listen-for-shutdown
systemctl start listen-for-shutdown
systemctl enable check-services-status-led
systemctl start check-services-status-led
