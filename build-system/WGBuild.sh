#!/bin/bash
# Build Wraithgram for the simulator (debug_sim_arm64), with bazel's progress visible.
#
#   build-system/WGBuild.sh [extra Make.py args...]      e.g. --continueOnError
#
# Config: build-system/wraithgram-configuration.json (gitignored, holds api_id / api_hash /
# team_id; the committed template is wraithgram-configuration.example.json, with Telegram's own
# public values, enough for the simulator; WGConfigCheck.py warns about them).
# Signing: the simulator ignores signatures, but Make.py still resolves aps-environment from a
# profile whose application-identifier is <team_id>.<bundle_id>. The fake profiles are issued for
# ph.telegra.Telegraph, so the Wraithgram profiles (build-system/wraithgram-codesigning, gitignored)
# are used when present; WG_CODESIGN overrides.
#
# Do not pipe this through grep: bazel's "[N / TOTAL] <action>" line is the only progress
# indicator. The full output goes to the log named below.

set -uo pipefail
cd "$(dirname "$0")/.."

CONFIG="build-system/wraithgram-configuration.json"
[ -f "$CONFIG" ] || { echo "ERROR: $CONFIG is missing — copy wraithgram-configuration.example.json and fill in the keys." >&2; exit 1; }
python3 build-system/WGConfigCheck.py "$CONFIG" || exit 1

CODESIGN="${WG_CODESIGN:-build-system/wraithgram-codesigning}"
SIM_PROFILES=0
if [ ! -d "$CODESIGN/profiles" ]; then
    # Telegram's fake profiles expired on 2026-10-30. The simulator ignores signatures, so build with
    # copies whose ExpirationDate is moved ahead (gitignored; regenerated on every run).
    CODESIGN="build-system/WGSimCodesigning"
    SIM_PROFILES=1
fi

LOG="${WG_BUILD_LOG:-/tmp/wg-build.log}"
echo "config     : $CONFIG"
echo "signing    : $CODESIGN"
echo "log        : $LOG"
echo

build-system/WGXcodeConfig.sh || exit 1

# Our changes inside submodules live as patches (a submodule commit would point at nothing upstream).
# Each is applied once per checkout; an already-applied patch is left alone.
apply_patch() {
    local dir="$1" patch="$2"
    local abs_patch
    abs_patch="$(pwd)/$patch"
    if git -C "$dir" apply --check "$abs_patch" 2>/dev/null; then
        git -C "$dir" apply "$abs_patch" && echo "patched    : $dir ($patch)"
    elif ! git -C "$dir" apply --reverse --check "$abs_patch" 2>/dev/null; then
        echo "ERROR: $patch neither applies nor is already applied — $dir changed, update the patch." >&2
        exit 1
    fi
}
# rules_apple's strip action ignores --action_env (see WGXcodeConfig.sh).
apply_patch build-system/bazel-rules/rules_apple build-system/WGPatches/rules_apple-strip-shell-env.patch
# Masks and the virtual camera in calls (W3-2): the frame hook in tgcalls' camera capturer.
apply_patch submodules/TgVoipWebrtc/tgcalls build-system/WGPatches/tgcalls-call-camera-masks.patch

# WGBuildRelease.sh reuses the patch step only.
[ "${WG_PATCHES_ONLY:-0}" = "1" ] && exit 0
if [ "$SIM_PROFILES" = "1" ]; then
    # The test profiles are Telegram's (team C67CF9S4VU, ph.telegra.Telegraph): retarget them to the
    # configuration's bundle ID and build with a copy of the configuration that names their team.
    SIM_CONFIG="build-system/wraithgram-configuration-sim.json"
    python3 - "$CONFIG" "$SIM_CONFIG" <<'PY' || exit 1
import json, sys
config = json.load(open(sys.argv[1]))
config['team_id'] = 'C67CF9S4VU'
config.pop('app_group', None)
json.dump(config, open(sys.argv[2], 'w'), indent=2)
PY
    chmod 600 "$SIM_CONFIG"
    BUNDLE_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["bundle_id"])' "$SIM_CONFIG")"
    python3 build-system/WGSimProfiles.py build-system/fake-codesigning "$CODESIGN" "$BUNDLE_ID" || exit 1
    CONFIG="$SIM_CONFIG"
fi

# Bazel's disk cache: WG_BAZEL_CACHE moves it, an empty value turns it off (CI, a small disk).
CACHE_ARGS=()
CACHE_DIR="${WG_BAZEL_CACHE-$HOME/telegram-bazel-cache}"
[ -n "$CACHE_DIR" ] && CACHE_ARGS=(--cacheDir "$CACHE_DIR")
python3 build-system/Make/Make.py --overrideXcodeVersion \
    "${CACHE_ARGS[@]+"${CACHE_ARGS[@]}"}" \
    build \
    --configurationPath "$CONFIG" \
    --codesigningInformationPath "$CODESIGN" \
    --buildNumber=1 --configuration=debug_sim_arm64 \
    "$@" 2>&1 | tee "$LOG"

# PIPESTATUS[0] is Make.py's status; [1] would be tee's, which is always 0.
status=${PIPESTATUS[0]}
echo
if [ "$status" = "0" ]; then
    echo "BUILD OK"
else
    echo "BUILD FAILED (exit $status) — errors:"
    grep -E "^ERROR:|error: " "$LOG" | head -20
fi
exit "$status"
