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

## Create the meta package Mizux.Foo
dotnet build src/Foo
dotnet pack src/Foo

## try consuming it
dotnet build -r linux-x64 example/Example
