#!/bin/bash
#
# Gradle wrapper script for flowTop.
#
# This script downloads and runs Gradle if it is not already available locally.
# If a GRADLE_HOME or gradle binary is on PATH, it is used directly.
#

set -e

APP_NAME="flowTop"
GRADLE_VERSION="8.1.1"
GRADLE_DISTRIBUTION_URL="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

# Resolve the directory containing this script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use local Gradle if available.
if command -v gradle >/dev/null 2>&1; then
  exec gradle "$@"
fi

# Check GRADLE_HOME.
if [ -n "${GRADLE_HOME:-}" ] && [ -x "${GRADLE_HOME}/bin/gradle" ]; then
  exec "${GRADLE_HOME}/bin/gradle" "$@"
fi

# Otherwise, attempt to download Gradle to the user home.
GRADLE_USER_HOME="${GRADLE_USER_HOME:-$HOME/.gradle}"
WRAPPER_DIST_PATH="${GRADLE_USER_HOME}/wrapper/dists"
INSTALL_MARKER="${WRAPPER_DIST_PATH}/gradle-${GRADLE_VERSION}-bin/installed"

if [ ! -f "$INSTALL_MARKER" ]; then
  echo "Gradle ${GRADLE_VERSION} not found locally."
  echo "To use the Gradle wrapper, install Gradle ${GRADLE_VERSION} and set GRADLE_HOME,"
  echo "or ensure the 'gradle' binary is on your PATH."
  echo ""
  echo "Example:"
  echo "  export GRADLE_HOME=/opt/gradle-${GRADLE_VERSION}"
  echo "  export PATH=\$GRADLE_HOME/bin:\$PATH"
  echo "  ./gradlew $*"
  exit 1
fi

# Use the locally installed wrapper distribution.
WRAPPER_GRADLE="${WRAPPER_DIST_PATH}/gradle-${GRADLE_VERSION}-bin/gradle-${GRADLE_VERSION}/bin/gradle"
if [ -x "$WRAPPER_GRADLE" ]; then
  exec "$WRAPPER_GRADLE" "$@"
fi

echo "Gradle wrapper distribution not found at $WRAPPER_GRADLE"
echo "Please install Gradle ${GRADLE_VERSION} manually."
exit 1
