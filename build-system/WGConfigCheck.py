#!/usr/bin/env python3
"""Checks a Wraithgram build configuration before a build.

    build-system/WGConfigCheck.py <configuration.json> [--device]

The committed template (wraithgram-configuration.example.json) holds Telegram's own public values from
Telegram-iOS (api_id 8, bundle ID ph.telegra.Telegraph) so that a simulator build works right away.
They are not meant for an app you install or share:

- api_id 8 is Telegram's own app: a warning on every build.
- the bundle ID ph.telegra.Telegraph makes a device IPA replace the official Telegram app:
  with --device, the build stops.

Exit status: 0 = go on (warnings may be printed), 1 = stop.
"""

import json
import sys

TELEGRAM_API_ID = "8"
TELEGRAM_BUNDLE_ID = "ph.telegra.Telegraph"


def main():
    args = [arg for arg in sys.argv[1:] if not arg.startswith("--")]
    device = "--device" in sys.argv[1:]
    if len(args) != 1:
        print("usage: WGConfigCheck.py <configuration.json> [--device]", file=sys.stderr)
        return 2
    path = args[0]
    try:
        with open(path) as file:
            config = json.load(file)
    except (OSError, ValueError) as error:
        print("ERROR: cannot read {}: {}".format(path, error), file=sys.stderr)
        return 1

    if str(config.get("api_id", "")) == TELEGRAM_API_ID:
        print("WARNING: {} uses Telegram's own api_id ({}).".format(path, TELEGRAM_API_ID), file=sys.stderr)
        print("         Get your own api_id and api_hash at https://my.telegram.org and put them in this file.", file=sys.stderr)
    if device and config.get("bundle_id") == TELEGRAM_BUNDLE_ID:
        print("ERROR: bundle_id in {} is Telegram's own ({}): an IPA with it replaces the official Telegram app.".format(path, TELEGRAM_BUNDLE_ID), file=sys.stderr)
        print("       Set your own bundle_id, for example com.yourname.wraithgram.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
