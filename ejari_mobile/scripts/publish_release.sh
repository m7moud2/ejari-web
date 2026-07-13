#!/usr/bin/env bash
# Publish Ejari Android APK to GitHub Releases and refresh public download links.
#
# Usage (from repo root or ejari_mobile):
#   ./ejari_mobile/scripts/publish_release.sh
#   ./ejari_mobile/scripts/publish_release.sh --demo   # DEMO_MODE=true
#   ./ejari_mobile/scripts/publish_release.sh --skip-build
#   ./ejari_mobile/scripts/publish_release.sh --notes-only
#
# Standard process after every app update:
#   1. Bump pubspec.yaml + AppConfig.appVersion
#   2. Run this script (build → copy → gh release → sed promo links)
#   3. git add / commit / push main so GitHub Pages picks up new links

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MOBILE_DIR/.." && pwd)"
REPO="m7moud2/ejari-web"

DEMO_MODE=false
SKIP_BUILD=false
NOTES_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --demo) DEMO_MODE=true; shift ;;
    --skip-build) SKIP_BUILD=true; shift ;;
    --notes) NOTES_FILE="${2:-}"; shift 2 ;;
    -h|--help)
      sed -n '2,16p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

cd "$MOBILE_DIR"

VERSION_LINE="$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}')"
VERSION_NAME="${VERSION_LINE%%+*}"
BUILD_NUMBER="${VERSION_LINE##*+}"
TAG="v${VERSION_NAME}"
APK_NAME="ejari-${VERSION_NAME}.apk"
APK_PATH="$MOBILE_DIR/releases/${APK_NAME}"
DIRECT_URL="https://github.com/${REPO}/releases/download/${TAG}/${APK_NAME}"
LATEST_URL="https://github.com/${REPO}/releases/latest"
PROMO_URL="https://m7moud2.github.io/ejari-web/promo/"
DOWNLOAD_PAGE="https://m7moud2.github.io/ejari-web/docs/download/"

echo "==> Version: ${VERSION_NAME}+${BUILD_NUMBER}  tag=${TAG}"

if [[ "$SKIP_BUILD" != true ]]; then
  echo "==> Building release APK (DEMO_MODE=${DEMO_MODE})..."
  flutter build apk --release --dart-define="DEMO_MODE=${DEMO_MODE}"
  mkdir -p "$MOBILE_DIR/releases"
  cp -f "$MOBILE_DIR/build/app/outputs/flutter-apk/app-release.apk" "$APK_PATH"
  echo "==> Copied → ${APK_PATH}"
else
  [[ -f "$APK_PATH" ]] || { echo "Missing ${APK_PATH}; build first or omit --skip-build" >&2; exit 1; }
fi

DEFAULT_NOTES="$(cat <<EOF
## ما الجديد في ${VERSION_NAME}

- بانر «التالي» أوضح لحجز المستأجر مع متابعة أسرع
- تحسين المفضلة وشارة الإشعارات
- فلاتر إقامة قصيرة / ساحل + ضمان بيانات العرض
- عدّاد تحميل فوري في صفحات الترويج

## التحميل

- مباشر: ${DIRECT_URL}
- أحدث إصدار: ${LATEST_URL}
- صفحة الترويج: ${PROMO_URL}
EOF
)"

if [[ -n "$NOTES_FILE" && -f "$NOTES_FILE" ]]; then
  NOTES="$(cat "$NOTES_FILE")"
else
  NOTES="$DEFAULT_NOTES"
fi

echo "==> Creating GitHub release ${TAG}..."
if ! gh auth status >/dev/null 2>&1; then
  cat >&2 <<'AUTH'
ERROR: GitHub CLI is not authenticated.

Run:
  gh auth login -h github.com
  # choose HTTPS → Login with a web browser (or paste a token with repo scope)

Then re-run this script with --skip-build if the APK already exists.
AUTH
  exit 1
fi

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "==> Release ${TAG} exists — uploading asset (clobber)..."
  gh release upload "$TAG" "$APK_PATH" --repo "$REPO" --clobber
  gh release edit "$TAG" --repo "$REPO" --title "Ejari ${VERSION_NAME}" --notes "$NOTES"
else
  gh release create "$TAG" "$APK_PATH" \
    --repo "$REPO" \
    --title "Ejari ${VERSION_NAME}" \
    --notes "$NOTES"
fi

echo "==> Updating public download links to ${VERSION_NAME}..."
python3 - "$VERSION_NAME" "$REPO_ROOT" <<'PY'
import re, sys
from pathlib import Path

version = sys.argv[1]
root = Path(sys.argv[2])
direct = f"https://github.com/m7moud2/ejari-web/releases/download/v{version}/ejari-{version}.apk"

files = [
    root / "promo/index.html",
    root / "promo/download.html",
    root / "promo/story.html",
    root / "docs/download/index.html",
    root / "ejari_mobile/releases/index.html",
    root / "ejari_mobile/web/download/index.html",
]

patterns = [
    (re.compile(r"https://github\.com/m7moud2/ejari-web/releases/download/v[\d.]+/ejari-[\d.]+\.apk"), direct),
    (re.compile(r"https://github\.com/m7moud2/ejari-web/releases/latest/download/ejari-[\d.]+\.apk"), direct),
    (re.compile(r"ejari-[\d.]+\.apk"), f"ejari-{version}.apk"),
    (re.compile(r"const APP_VERSION = '[^']+'"), f"const APP_VERSION = '{version}'"),
    (re.compile(r"الإصدار [\d.]+"), f"الإصدار {version}"),
    (re.compile(r"Ejari [\d.]+"), f"Ejari {version}"),
    (re.compile(r"\bv[\d.]+\b"), f"v{version}"),
]

# Safer targeted version display replacements for remaining hardcoded versions
extra = [
    (re.compile(r"إيجاري [\d.]+"), f"إيجاري {version}"),
    (re.compile(r"تطبيق إيجاري [\d.]+"), f"تطبيق إيجاري {version}"),
    (re.compile(r"ثم ثبّت [\d.]+"), f"ثم ثبّت {version}"),
]

for path in files:
    if not path.exists():
        print(f"  skip missing {path.relative_to(root)}")
        continue
    text = path.read_text(encoding="utf-8")
    orig = text
    for rx, repl in patterns + extra:
        text = rx.sub(repl, text)
    if text != orig:
        path.write_text(text, encoding="utf-8")
        print(f"  updated {path.relative_to(root)}")
    else:
        print(f"  unchanged {path.relative_to(root)}")
PY

# Keep releases/README.md current
README="$MOBILE_DIR/releases/README.md"
if [[ -f "$README" ]]; then
  python3 - "$VERSION_NAME" "$README" "$DIRECT_URL" <<'PY'
import re, sys
from pathlib import Path
version, path, direct = sys.argv[1], Path(sys.argv[2]), sys.argv[3]
text = path.read_text(encoding="utf-8")
text = re.sub(
    r"https://github\.com/m7moud2/ejari-web/releases/download/v[\d.]+/ejari-[\d.]+\.apk",
    direct,
    text,
)
text = re.sub(r"ejari-[\d.]+\.apk", f"ejari-{version}.apk", text)
text = re.sub(r"v[\d.]+", f"v{version}", text)
text = re.sub(r"Ejari [\d.]+", f"Ejari {version}", text)
path.write_text(text, encoding="utf-8")
print(f"  updated releases/README.md")
PY
fi

cat <<EOF

✅ Release published

| | |
|--|--|
| Version | ${VERSION_NAME}+${BUILD_NUMBER} |
| Direct APK | ${DIRECT_URL} |
| Latest | ${LATEST_URL} |
| Promo | ${PROMO_URL} |
| Download page | ${DOWNLOAD_PAGE} |

Next:
  cd ${REPO_ROOT}
  git add promo/ docs/download/ ejari_mobile/releases/ ejari_mobile/scripts/ ejari_mobile/web/download/
  git commit -m "Publish Ejari ${VERSION_NAME} and update download links"
  git push origin main
EOF
