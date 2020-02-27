#!/usr/bin/env bash
set -x -e

function installdotnetsdk(){
  sudo apt-get update -qq
  sudo apt-get install -yq apt-transport-https
  # see https://docs.microsoft.com/en-us/dotnet/core/install/linux-package-manager-ubuntu-1604
  wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb
  sudo dpkg -i packages-microsoft-prod.deb
  # Install dotnet sdk 3.1
  sudo apt-get update -qq
  sudo apt-get install -yqq dotnet-sdk-3.1
}

if [ "${TRAVIS_OS_NAME}" == linux ]; then
  installdotnetsdk
elif [ "${TRAVIS_OS_NAME}" == osx ]; then
  brew update;
  brew install make;
  brew cask install dotnet-sdk;
fi
