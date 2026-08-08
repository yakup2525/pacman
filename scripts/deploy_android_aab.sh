#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${PROJECT_ROOT}/deploy/android"
AAB_SOURCE="${PROJECT_ROOT}/build/app/outputs/bundle/release/app-release.aab"
KEY_PROPERTIES="${PROJECT_ROOT}/android/key.properties"
KEYSTORE="${PROJECT_ROOT}/android/upload-keystore.jks"

cd "${PROJECT_ROOT}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter bulunamadi. PATH ayarlarini kontrol edin."
  exit 1
fi

if [[ ! -f "${KEY_PROPERTIES}" ]]; then
  echo "android/key.properties bulunamadi."
  exit 1
fi

if [[ ! -f "${KEYSTORE}" ]]; then
  echo "android/upload-keystore.jks bulunamadi."
  exit 1
fi

VERSION="$(grep '^version:' pubspec.yaml | awk '{print $2}')"
DATE="$(date +%Y-%m-%d)"
OUTPUT_FILE="${OUTPUT_DIR}/ghost_runner_${VERSION}_${DATE}.aab"

echo "Flutter bagimliliklari kontrol ediliyor..."
flutter pub get

echo "Release AAB build baslatiliyor..."
flutter build appbundle --release

if [[ ! -f "${AAB_SOURCE}" ]]; then
  echo "AAB dosyasi olusturulamadi: ${AAB_SOURCE}"
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"
cp "${AAB_SOURCE}" "${OUTPUT_FILE}"

echo ""
echo "Deploy ciktisi hazir:"
echo "  ${OUTPUT_FILE}"
echo ""
echo "Google Play Console'a yuklemek icin bu dosyayi kullanabilirsiniz."
