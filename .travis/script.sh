#!/usr/bin/env bash
set -x
set -e

dotnet --info

#################
##  CONFIGURE  ##
#################
if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
  export PATH=/opt/cmake-3.16.2/bin:$PATH
fi
if [ "${TRAVIS_OS_NAME}" == osx ];then
  # Installer changes path but won't be picked up in current terminal session
  # Need to explicitly add location
  export PATH=/usr/local/share/dotnet:"${PATH}"
fi
cmake --version
cmake -S. -Bbuild

#############
##  BUILD  ##
#############
cmake --build build --target all -- VERBOSE=1

############
##  TEST  ##
############
cmake --build build --target test
# vim: set tw=0 ts=2 sw=2 expandtab:
