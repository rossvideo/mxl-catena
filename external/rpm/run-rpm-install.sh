#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/platform_manager"
ARCHIVE="$(ls -1 /tmp/rpm/PlatformManager-*.tar.gz 2>/dev/null | head -n 1 || true)"
MARKER_FILE="${APP_DIR}/.rpm_installed"

if [[ -z "${ARCHIVE}" ]]; then
  echo "No PlatformManager tarball found in /tmp/rpm"
  exit 1
fi

if [[ ! -f "${MARKER_FILE}" ]]; then
  mkdir -p "${APP_DIR}"
  tar -xvf "${ARCHIVE}" -C "${APP_DIR}"
  chmod -R 755 "${APP_DIR}"

  INSTALL_PATH="${APP_DIR}/Install"
  if [[ ! -f "${INSTALL_PATH}" ]]; then
    INSTALL_PATH="$(find "${APP_DIR}" -maxdepth 2 -type f -name Install | head -n 1 || true)"
  fi

  if [[ -z "${INSTALL_PATH}" || ! -f "${INSTALL_PATH}" ]]; then
    echo "Install script was not found after extraction in ${APP_DIR}"
    exit 1
  fi

  chmod +x "${INSTALL_PATH}"
  (
    cd "$(dirname "${INSTALL_PATH}")"
    sh ./Install
  )

  touch "${MARKER_FILE}"
fi
# Keep container alive if installer exits.
tail -f /dev/null
