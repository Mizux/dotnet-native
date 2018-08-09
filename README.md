[![Build
Status](https://travis-ci.org/Mizux/dotnet.svg?branch=master)](https://travis-ci.org/Mizux/dotnet)

# Introduction
Try to build a Native (win-x64, linux-x64, osx-x64) C# Netstandard2.0 package.  
e.g. You have a cross platform C++ library with .Net wrapper thanks to SWIG.  
Then you want to provide a cross platform nuget package to consume it in a "pure" .Net Project...

# Requirement
You'll need the ".Net Core SDK 2.1.302" !

# Layout

* [`src/Foo.linux-x64`](src/Foo.linux-x64) Contains the hypothetical C++ unix 64bits shared library with its C# wrapper source code.
* [`src/Foo.osx-x64`](src/Foo.osx-x64) Contains the hypothetical C++ osx 64bits shared library with its C# wrapper source code.
* [`src/Foo.win-x64`](src/Foo.win-x64) Contains the hypothetical C++ win 64bits shared library with its C# wrapper source code.

* [`src/Foo`](src/Foo) Is a Generic C# library which depends on all previous package according to the runtime identifier set on the cli.
* [`src/FooApp`](src/FooApp) Is a Generic C# application using the meta Foo library.

```
Foo.linux-x64 -+
Foo.osx-x64 ---+-> Foo -> FooApp
Foo.win-x64 ---+
```

# Build process
We want two modes:
1. Locally, be able to only build/pack for the current host machine i.e. passing a [Runtime Identifier (RID)](https://docs.microsoft.com/en-us/dotnet/core/rid-catalog)
2. Be able to create a multi-platforms (ed. here platform means OS) Foo package provided you have the three Native Foo.*-x64 package already available on Nuget.org.  
i.e. You have already publish the Native packages...

## Linux Use Case
### Building
You can build using the command:
```bash
dotnet build --runtime linux-x64 src/FooApp/FooApp.csproj
Microsoft (R) Build Engine version 15.7.179.6572 for .NET Core
Copyright (C) Microsoft Corporation. All rights reserved.

  Restore completed in 55.96 ms for ...dotnet/src/Foo.linux-x64/Foo.linux-x64.csproj.
  Restore completed in 55.96 ms for .../dotnet/src/FooApp/FooApp.csproj.
  Restore completed in 55.96 ms for .../dotnet/src/Foo/Foo.csproj.
  Foo.linux-x64 -> .../dotnet/src/Foo.linux-x64/bin/Debug/netstandard2.0/linux-x64/Foo.linux-x64.dll
  Foo -> .../dotnet/src/Foo/bin/Debug/netstandard2.0/linux-x64/Foo.dll
  FooApp -> .../dotnet/src/FooApp/bin/Debug/netcoreapp2.1/linux-x64/Mizux.FooApp.dll

Build succeeded.
    0 Warning(s)
    0 Error(s)
```

### Running
You can try running using:
```bash
dotnet .../dotnet/src/FooApp/bin/Debug/netcoreapp2.1/linux-x64/Mizux.FooApp.dll
Hello from FooApp!
Hello from Foo!
Hello from Foo.linux-x64!
```

### Packing
let's try to first pack Foo.linux-x64:
```bash
dotnet pack src/Foo.linux-x64/Foo.linux-x64.csproj -o ../../package
Microsoft (R) Build Engine version 15.7.179.6572 for .NET Core
Copyright (C) Microsoft Corporation. All rights reserved.

  Restore completed in 64.86 ms for .../dotnet/src/Foo.linux-x64/Foo.linux-x64.csproj.
  Foo.linux-x64 -> .../dotnet/src/Foo.linux-x64/bin/Debug/netstandard2.0/linux-x64/Foo.linux-x64.dll
  Successfully created package '.../dotnet/package/Foo.linux-x64.1.0.0.nupkg'.
```
Let's take a look at the layout
```bash
unzip -l package/Foo.linux-x64.1.0.0.nupkg
Archive:  package/Foo.linux-x64.1.0.0.nupkg
  Length      Date    Time    Name
---------  ---------- -----   ----
      503  2018-08-09 16:51   _rels/.rels
      497  2018-08-09 16:51   Foo.linux-x64.nuspec
     3584  2018-08-09 14:42   lib/netstandard2.0/Foo.linux-x64.dll
        0  2018-08-09 12:04   runtimes/linux-x64/netstandard2.0/plop.so
      520  2018-08-09 16:51   [Content_Types].xml
      632  2018-08-09 16:51   package/services/metadata/core-properties/3c4a144ec0f241cd9771e06f9a1479db.psmdcp
---------                     -------
     5736                     6 files
```

## MacOS Use Case
ToDo

## Windows Use Case
ToDo

# Issue
I was not able to put the .dll of any `Foo.*-x64` package in `runtimes/*-x64/netstandard2.0/Foo.*-x64.dll` like recommended...

