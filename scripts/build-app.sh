#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

echo "==> Building MacStatusApp in release mode..."
swift build -c release

APP_NAME="MacStatus.app"
BUILD_DIR="${ROOT_DIR}/build"
APP_DIR="${BUILD_DIR}/${APP_NAME}"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "==> Packaging ${APP_NAME}..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp ".build/release/MacStatusApp" "${MACOS_DIR}/MacStatusApp"
chmod +x "${MACOS_DIR}/MacStatusApp"

cp "Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"

if [ -f "Resources/AppIcon.icns" ]; then
    echo "==> Copying AppIcon.icns..."
    cp "Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

echo "==> Ad-hoc signing ${APP_NAME}..."
codesign -s - --force --deep "${APP_DIR}"

echo "==> Success! ${APP_DIR} created."
