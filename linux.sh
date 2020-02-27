#/usr/bin/env bash
set -e -x

# Cleaning
git clean -fdx
dotnet nuget locals all --clear

# Testing
## Create the three natives packages runtime.{rid}.Mizux.Foo
dotnet build runtime.linux-x64.Mizux.Foo
dotnet pack runtime.linux-x64.Mizux.Foo

dotnet build runtime.osx-x64.Mizux.Foo
dotnet pack runtime.osx-x64.Mizux.Foo

dotnet build runtime.win-x64.Mizux.Foo
dotnet pack runtime.win-x64.Mizux.Foo

### list content of each nupkg
for i in packages/*.nupkg; do unzip -l $i; done

## Create the meta package Mizux.Foo
dotnet build Mizux.Foo
dotnet pack Mizux.Foo
unzip -l packages/Mizux.Foo.*.nupkg

## try consuming it
dotnet build Mizux.FooApp
dotnet run --project Mizux.FooApp

## Try unit test
dotnet build Mizux.Foo.Tests
dotnet test Mizux.Foo.Tests
