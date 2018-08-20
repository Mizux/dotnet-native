#/usr/bin/env bash
set -e -x

# Cleaning
git clean -fdx
dotnet nuget locals all --clear

# Testing
## Create the three natives packages runtime.{rid}.Mizux.Foo
dotnet build src/runtime.linux-x64.Foo
dotnet pack src/runtime.linux-x64.Foo

dotnet build src/runtime.osx-x64.Foo
dotnet pack src/runtime.osx-x64.Foo

dotnet build src/runtime.win-x64.Foo
dotnet pack src/runtime.win-x64.Foo

### list content of each nupkg
for i in package/*.nupkg; do unzip -l $i; done

## Create the meta package Mizux.Foo
dotnet build src/Foo
unzip -l package/Mizux.Foo.1.0.0.nupkg

## try consuming it
dotnet build -r linux-x64 example/Example
