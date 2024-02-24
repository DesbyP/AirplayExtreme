#! /usr/bin/env python
import datetime
import os
import sys
import time
import signal
import subprocess

import RPi.GPIO as GPIO


SERVICE_GPIO_MAP = {
    "network-online.target": 17,
    "shairport-sync": 27,
}


def turn_off_leds_and_exit(signal, stackframe):
    for gpio in SERVICE_GPIO_MAP.values():
        print(f"turning off {gpio}...")
        GPIO.output(gpio, GPIO.LOW) 
    print("LEDs turned off")
    sys.exit(signal)


def check_service_status(service, gpio, night_mode):
    cmd = subprocess.Popen(
        "systemctl status {} --no-pager -n 0".format(service).split(),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    cmd_out, cmd_err = cmd.communicate()
    if (cmd.returncode or night_mode) and GPIO.input(gpio):  # turn off if service is down OR nightmode is forced AND LED is on
        print(f"turning off {gpio}...")
        GPIO.output(gpio, GPIO.LOW)
    elif not GPIO.input(gpio):  # turn on if service is up AND LED is off
        print(f"turning on {gpio}...")
        GPIO.output(gpio, GPIO.HIGH)

    if "underrun occured" in cmd_out.decode():
        print("restarting {}".format(service))
        subprocess.call("systemctl restart {}".format(service))


if __name__ == '__main__':

    # setup parameters

    night_mode_forced = None
    if 'NIGHTMODE' in os.environ:
        night_mode_forced = str(os.environ['NIGHTMODE']).lower() in ['1', 'yes', 'true']

    # setup GPIOs
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(list(SERVICE_GPIO_MAP.values()) + [14], GPIO.OUT)

    # setup exit handler
    signal.signal(signal.SIGTERM, turn_off_leds_and_exit)
    signal.signal(signal.SIGINT, turn_off_leds_and_exit)

    # turn on "power" LED
    print(f"turning on 'power' (22)...")
    GPIO.output(22, GPIO.HIGH)

    # infinite loop
    while True:
        if night_mode_forced is not None:
            night_mode = night_mode_forced
        else:
            utc_now = datetime.datetime.utcnow()
            hour = utc_now.hour + 1
            if hour >= 23 or hour < 8:
                night_mode = True
            else:
                night_mode = False

        for service, port in SERVICE_GPIO_MAP.items():
            check_service_status(service, port, night_mode)

        time.sleep(3)
