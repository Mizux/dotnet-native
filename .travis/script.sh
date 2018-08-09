#!/usr/bin/env bash
set -x -e

dotnet --info

if [ "${TRAVIS_OS_NAME}" == linux ];then
 dotnet build --runtime linux-x64 src/FooApp/FooApp.csproj;
 dotnet src/FooApp/bin/Debug/netcoreapp2.1/linux-x64/Mizux.FooApp.dll;
 dotnet pack src/Foo.linux-x64/Foo.linux-x64.csproj -o ../../package;
 unzip -l package/Foo.linux-x64.1.0.0.nupkg;
elif [ "${TRAVIS_OS_NAME}" == osx ];then
 dotnet build --runtime osx-x64 src/FooApp/FooApp.csproj;
 dotnet src/FooApp/bin/Debug/netcoreapp2.1/osx-x64/Mizux.FooApp.dll;
 dotnet pack src/Foo.osx-x64/Foo.osx-x64.csproj -o ../../package;
 unzip -l package/Foo.osx-x64.1.0.0.nupkg;
fi
