#!/usr/bin/env bash
set -x -e

if [ "${TRAVIS_OS_NAME}" == linux ]; then
  # Installs for Ubuntu Trusty distro
  sudo apt-get update -q &&
  sudo apt-get install -y -q curl apt-transport-https
  curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg &&
  sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg &&
  sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-trusty-prod trusty main" > /etc/apt/sources.list.d/dotnetdev.list' &&
  sudo apt-get update -q &&
  sudo apt-get install -y -q dotnet-sdk-2.1
elif [ "${TRAVIS_OS_NAME}" == osx ]; then
  brew update;
  brew tap caskroom/cask;
  brew cask install dotnet-sdk;
fi
