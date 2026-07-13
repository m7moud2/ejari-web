#!/usr/bin/env bash
# Thin wrapper — canonical script lives in ejari_mobile/scripts/
exec "$(cd "$(dirname "$0")/.." && pwd)/ejari_mobile/scripts/publish_release.sh" "$@"
