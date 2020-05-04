#!/usr/bin/env bash
set -x
set -e

function install-cmake() {
  # need CMake >= 3.14 (for using the newly swig built-in UseSWIG module)
  if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
    wget "https://cmake.org/files/v3.17/cmake-3.17.2-Linux-x86_64.sh"
    chmod a+x cmake-3.17.2-Linux-x86_64.sh
    sudo ./cmake-3.17.2-Linux-x86_64.sh --prefix=/usr/local/ --skip-license
    rm cmake-3.17.2-Linux-x86_64.sh
    export PATH=/usr/local/bin:$PATH
    command -v cmake
    cmake --version
  elif [ "$TRAVIS_OS_NAME" == "osx" ]; then
    cmake --version
  fi
}

function install-swig() {
  if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
    # apt-get only have swig 2.0.11
    # Need SWIG >= 3.0.8
    cd /tmp/
    wget https://github.com/swig/swig/archive/rel-4.0.1.tar.gz
    tar zxf rel-4.0.1.tar.gz
    cd swig-rel-4.0.1
    ./autogen.sh
    ./configure --prefix=/usr
    make -j 2
    sudo make install
  elif [ "$TRAVIS_OS_NAME" == "osx" ]; then
    brew install swig
  fi
}

function install-dotnet-sdk(){
  if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
    # see https://docs.microsoft.com/en-us/dotnet/core/install/linux-package-manager-ubuntu-1804
    sudo apt-get install -yq apt-transport-https
    wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    sudo apt-get update -qq
    sudo apt-get install -yq dotnet-sdk-3.1
  elif [ "$TRAVIS_OS_NAME" == "osx" ]; then
    #brew tap homebrew/cask-cask
    brew cask install dotnet-sdk
    dotnet --info
  fi
}

install-cmake
install-swig
install-dotnet-sdk
# vim: set tw=0 ts=2 sw=2 expandtab:
