#!/usr/bin/env bash
set -x -e
if [ "${TRAVIS_OS_NAME}" == osx ];then
  # Installer changes path but won't be picked up in current terminal session
  # Need to explicitly add location
  export PATH=/usr/local/share/dotnet:"${PATH}";
fi

dotnet --info

if [ "${TRAVIS_OS_NAME}" == linux ];then
  dotnet build src/runtime.linux-x64.Foo;
  dotnet pack src/runtime.linux-x64.Foo;
elif [ "${TRAVIS_OS_NAME}" == osx ];then
  dotnet build src/runtime.osx-x64.Foo;
  dotnet pack src/runtime.osx-x64.Foo;
fi
dotnet build src/Foo;
dotnet pack src/Foo;
for i in package/*; do
  unzip -l $i;
done

dotnet build src/FooApp;
dotnet run --project src/FooApp;
