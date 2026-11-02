"""WiFi bring-up and reconnection."""

import network
import time


def connect(ssid, password, static_ip=None, hostname=None, timeout_s=30):
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)

    if hostname:
        try:
            network.hostname(hostname)
        except (AttributeError, OSError):
            # Older firmware without network.hostname(); harmless to skip.
            pass

    if static_ip:
        wlan.ifconfig(static_ip)

    if not wlan.isconnected():
        print("wifi: connecting to", ssid)
        wlan.connect(ssid, password)
        deadline = time.ticks_add(time.ticks_ms(), timeout_s * 1000)
        while not wlan.isconnected():
            if time.ticks_diff(deadline, time.ticks_ms()) <= 0:
                raise OSError("wifi: timed out connecting to %s" % ssid)
            time.sleep(0.25)

    print("wifi: connected, ifconfig =", wlan.ifconfig())
    return wlan


def ensure(wlan, ssid, password):
    """Re-associate if the link dropped. Returns True if currently connected."""
    if wlan.isconnected():
        return True
    print("wifi: link lost, reconnecting")
    try:
        wlan.disconnect()
    except OSError:
        pass
    try:
        wlan.connect(ssid, password)
    except OSError as e:
        print("wifi: reconnect failed:", e)
    return wlan.isconnected()
