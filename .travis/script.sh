#!/usr/bin/env bash
set -x -e
if [ "${TRAVIS_OS_NAME}" == osx ];then
  # Installer changes path but won't be picked up in current terminal session
  # Need to explicitly add location
  export PATH=/usr/local/share/dotnet:"${PATH}";
fi

dotnet --info

make build_${TRAVIS_OS_NAME}
make pack_${TRAVIS_OS_NAME}

make build
make pack

make test
