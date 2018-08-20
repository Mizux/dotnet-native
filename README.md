[![Build
Status](https://travis-ci.org/Mizux/dotnet.svg?branch=master)](https://travis-ci.org/Mizux/dotnet)
[![Build status](https://ci.appveyor.com/api/projects/status/xbtj9qs2s3d5u2dj/branch/master?svg=true)](https://ci.appveyor.com/project/Mizux/dotnet/branch/master)

# Introduction
Try to build a netstandard2.0 native (for win-x64, linux-x64 and osx-x64) nuget package using [`dotnet/cli`](https://github.com/dotnet/cli).  
e.g. You have a cross platform C++ library and a netstandard2.0 wrapper thanks to SWIG.  
Then you want to provide a cross platform nuget package to consume it in a "pure" .Net Project...

# Requirement
You'll need the ".Net Core SDK 2.1.302" to get the dotnet cli.
i.e. We won't/can't rely on VS since we want a portable cross-platform cli process. 

# Layout
* [`src/runtime.linux-x64.Foo`](src/runtime.linux-x64.Foo) Contains the hypothetical C++ unix 64bits shared library with its wrapper source code.
* [`src/runtime.osx-x64.Foo`](src/runtime.osx-x64.Foo) Contains the hypothetical C++ osx 64bits shared library with its C# wrapper source code.
* [`src/runtime.win-x64.Foo`](src/runtime.win-x64.Foo) Contains the hypothetical C++ win 64bits shared library with its C# wrapper source code.

* [`src/Foo`](src/Foo) Is a Generic C# library which depends on all previous package according to the runtime identifier set on the cli.
* [`src/FooApp`](src/FooApp) Is a Generic C# Project Application with a **`ProjectReference`** to `Foo` project.


# Build process
We want two use case scenario:
1. Locally, be able to only build for the current host `OS Platform` i.e. passing a [Runtime Identifier (RID)](https://docs.microsoft.com/en-us/dotnet/core/rid-catalog)  
Here we "chain" project using `ProjectReference`.  
note: This is usefull when the C++ has a complex/custom build process for Windows, Linux and MacOS. 
i.e. You can generate the .Net wrapper and shared library which is specific for each OS Platform only on this Os Platform (i.e. no cross compilation available/supported for the native library).
```
Native.cpp -(GCC)-> Native.so --------+
Native.cpp -(SWIG)-> Native.{rid}.cs -+-> runtime.{rid}.Foo.csproj -(ProjectReference)> Foo.csproj -(ProjectReference)> FooApp.csproj
```

2. Be able to create a cross-platform (ed "OS" Platform like linux-x64 not "Target" Platform like netstandard2.0) Foo package provided you have the three native Foo.*-x64 package already available on Nuget.org (or locally).  
Here we "chain" project using `PackageReference` since we can't build all OS platform package on one platform.  
i.e. You have already generated the Native packages on each architecture:
```
package/runtime.linux-x64.Mizux.Foo.nupkg -+
package/runtime.osx-x64.Mizux.Foo.nupkg ---+-(PackageReference)> Foo.csproj -(build)> Mizux.Foo.nupkg -(PackageReference)> Example.csproj
package/runtime.win-x64.Mizux.Foo.nupkg ---+
```

## Use Case Scenario 1: FooApp using Foo.csproj
We would like to build `Foo.csproj` which only depends on `Foo.linux-x64.csproj` in order to test locally.  
note: The pipeline will be similar for osx-x64 and win-x64 architecture, don't hesitate to look at the CI log.
```
Native.cpp -(GCC)-> Native.so --------+
Native.cpp -(SWIG)-> Native.linux.cs -+-> runtime.linux-x64.Foo.csproj -(ProjectReference)> Foo.csproj -(ProjectReference)> FooApp.csproj
```
note: we suppose the `GCC` and `SWIG` has already been performed so we have the `Native.so` and `Native.linux.so` already provided in this sample repository.

### Building
To only depends on a specific project according to the targeted RID you can use
```xml
<ItemGroup Condition="'$(RuntimeIdentifier)' == 'linux-x64'">
  <ProjectReference Include="..\runtime.linux-x64.Foo\project.csproj" />
</ItemGroup>
```
src: https://github.com/Mizux/dotnet/blob/master/src/Foo/Foo.csproj#L17

You can build using the dotnet\cli command with the `--runtime linux-x64` option:
```bash
# build the shared library from the C++ source code
# Generate the .cs wrapper from the C++ source code using SWIG
dotnet build --runtime linux-x64 src/FooApp/FooApp.csproj
Microsoft (R) Build Engine version 15.7.179.6572 for .NET Core
Copyright (C) Microsoft Corporation. All rights reserved.

  Restore completed in 55.96 ms for ...dotnet/src/runtime.linux-x64.Foo/project.csproj.
  Restore completed in 55.96 ms for .../dotnet/src/FooApp/FooApp.csproj.
  Restore completed in 55.96 ms for .../dotnet/src/Foo/Foo.csproj.
  runtime.linux-x64.Foo -> .../dotnet/src/Foo.linux-x64/bin/Debug/netstandard2.0/linux-x64/Foo.linux-x64.dll
  Foo -> .../dotnet/src/Foo/bin/Debug/netstandard2.0/linux-x64/Foo.dll
  FooApp -> .../dotnet/src/FooApp/bin/Debug/netcoreapp2.1/linux-x64/Mizux.FooApp.dll

Build succeeded.
    0 Warning(s)
    0 Error(s)
```
You can see that `Foo.osx-x64.csproj` and `Foo.win-x64.csproj` are ignored during build.  
Also since we specify a RID the outputpath is `bin/$(Configuration)/$(TargetFramework)/$(RuntimeIdentifier)`.

### Running
You can try running the FooApp using:
```bash
dotnet .../dotnet/src/FooApp/bin/Debug/netcoreapp2.1/linux-x64/Mizux.FooApp.dll
[1] Enter FooApp
[2] Enter Foo
[3] Enter Foo.linux-x64
[3] Exit Foo.linux-x64
[2] Exit Foo
[1] Exit FooApp
```

note: `dotnet run -r linux-x64 --project ...` doesn't work (Bug ?) since contrary to the build command the `--runtime` is "ignored" and dotnet look for `bin/$(Configuration)/$(TargetFramework)/Mizux.FooApp.dll` (note the missing RID in the path).

### Packing RID dependent project: Mizux.Foo.{rid}
Let's try to first pack `Foo.linux-x64`. Since it is architecture dependent you need to put file in
`runtimes/{rid}/lib/{tfm}/*.dll`.  
src: https://natemcmaster.com/blog/2016/05/19/nuget3-rid-graph/#what-goes-in-the-runtimes-folder

You can use:
```xml
<BuildOutputTargetFolder>runtimes/linux-x64/lib</BuildOutputTargetFolder>
```
to put the output assembly in the correct directory inside the nuget package.  
For the shared library simply use:
```xml
<ItemGroup>
  <Content Include="*.so">
    <PackagePath>runtimes/linux-x64/lib/netstandard2.0/%(Filename)%(Extension)</PackagePath>
    <Pack>true</Pack>
    <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
  </Content>
</ItemGroup>
```

```bash
dotnet pack src/Foo.linux-x64
Microsoft (R) Build Engine version 15.7.179.6572 for .NET Core
Copyright (C) Microsoft Corporation. All rights reserved.

  Restore completed in 64.86 ms for .../dotnet/src/Foo.linux-x64/Foo.linux-x64.csproj.
  Foo.linux-x64 -> .../dotnet/src/Foo.linux-x64/bin/Debug/netstandard2.0/linux-x64/Foo.linux-x64.dll
  Successfully created package '.../dotnet/package/Foo.linux-x64.1.0.0.nupkg'.
```
Let's take a look at the layout
```bash
unzip -l package/Mizux.Foo.linux-x64.1.0.0.nupkg
Archive:  package/Mizux.Foo.linux-x64.1.0.0.nupkg
  Length      Date    Time    Name
---------  ---------- -----   ----
      ...  2018-00-00 00:42   _rels/.rels
      ...  2018-00-00 00:42   Mizux.Foo.linux-x64.nuspec
     ....  2018-00-00 00:42   runtimes/linux-x64/lib/netstandard2.0/Mizux.Foo.linux-x64.dll
     ....  2018-00-00 00:42   runtimes/linux-x64/lib/netstandard2.0/Native.so
      ...  2018-00-00 00:42   [Content_Types].xml
      ...  2018-00-00 00:42   package/services/metadata/core-properties/3c4a144ec0f241cd9771e06f9a1479db.psmdcp
---------                     -------
     ....                     6 files
```

## Use Case Scenario 2: Example using Mizux.Foo.*.nupkg
We would like to build `Exemple.csproj` which only depends (i.e. `PackageReference`) on `Mizux.Foo` nuget package in order to test locally.  
note: This pipeline should be run on any architecture,
provided you have generated the three architecture dependent `Foo.{rid}` nuget package.
```
package/Mizux.Foo.linux-x64.nupkg -+
package/Mizux.Foo.osx-x64.nupkg ---+-(PackageReference)> Mizux.Foo.nupkg -(PackageReference)> Mizux.Example.csproj
package/Mizux.Foo.win-x64.nupkg ---+
```
note: we suppose the three OS platform dependent package have been generated using the use case scenario 1.

### Packing meta project: Mizux.Foo
Let's try to first pack `Foo`. Since it is architecture independent you need to put file in `lib/{tfm}/*.dll`.  

To make `Mizux.Foo` dependent on `Mizux.Foo.{rid}` we use a `runtime.json` file containing:
```json
{
  "runtimes": {
    "linux-x64": {
      "Mizux.Foo": {
        "Mizux.Foo.linux-x64": "1.0.0"
      }
    },
    "osx-x64": {
      "Mizux.Foo": {
        "Mizux.Foo.osx-x64": "1.0.0"
      }
    },
    "win-x64": {
      "Mizux.Foo": {
        "Mizux.Foo.win-x64": "1.0.0"
      }
    }
  }
}
```
src: https://github.com/Mizux/dotnet/blob/master/src/Foo/runtime.json  
And you can add it to the nuget package using in the .csproj:
```xml
<ItemGroup Condition="'$(RuntimeIdentifier)' == ''">
  <Content Include="runtime.json">
    <PackagePath>runtime.json</PackagePath>
    <Pack>true</Pack>
    <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
  </Content>
</ItemGroup>
```

You can use:
```bash
dotnet build src/Foo
Microsoft (R) Build Engine version 15.7.179.6572 for .NET Core
Copyright (C) Microsoft Corporation. All rights reserved.

Restore completed in 37.37 ms for .../dotnet/src/Foo/Foo.csproj.
Foo -> .../dotnet/src/Foo/bin/Debug/netstandard2.0/Mizux.Foo.dll
Successfully created package '.../package/Mizux.Foo.1.0.0.nupkg'
```
Also since we **don't** specify a RID the outputpath is `bin/$(Configuration)/$(TargetFramework)`.

**/!\ I didn't manage to add a Foo.cs file (depending on Mizux.Foo.{RID}) when no RID is specified /!\  
I think I should try to use a Reference Assembly (once it will be clearly documented how it works with native libs)**

Let's take a look at the layout
```bash
unzip -l package/Mizux.Foo.1.0.0.nupkg
Archive:  package/Mizux.Foo.1.0.0.nupkg
  Length      Date    Time    Name
---------  ---------- -----   ----
      ...  2018-00-00 00:42   _rels/.rels
      ...  2018-00-00 00:42   Mizux.Foo.nuspec
     ....  2018-00-00 00:42   lib/netstandard2.0/Mizux.Foo.dll
     ....  2018-00-00 00:42   runtime.json
      ...  2018-00-00 00:42   [Content_Types].xml
      ...  2018-00-00 00:42   package/services/metadata/core-properties/3c4a144ec0f241cd9771e06f9a1479db.psmdcp
---------                     -------
     ....                     6 files
```
