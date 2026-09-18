#!/usr/bin/env bash
# Prints the UDID of an available iPhone simulator, preferring the iOS runtime
# whose major version matches the selected Xcode's simulator SDK, then the
# newest runtime. Used by CI so the destination never depends on device names.
set -euo pipefail
sdk_major="$(xcrun --sdk iphonesimulator --show-sdk-version | cut -d. -f1)"
xcrun simctl list devices available -j | python3 -c '
import json, re, sys
sdk_major = int(sys.argv[1])
candidates = []
for runtime, devices in json.load(sys.stdin)["devices"].items():
    match = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not match:
        continue
    version = (int(match.group(1)), int(match.group(2)))
    for device in devices:
        if device.get("isAvailable") and device["name"].startswith("iPhone"):
            candidates.append((version[0] == sdk_major, version, device["name"], device["udid"]))
if not candidates:
    sys.exit("no available iPhone simulator")
candidates.sort(reverse=True)
print(candidates[0][3])
' "$sdk_major"
