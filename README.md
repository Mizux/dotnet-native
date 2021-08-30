[![Build Status][docker_status]][docker_link]
[![Status][linux_svg]][linux_link]
[![Status][osx_svg]][osx_link]
[![Status][win_svg]][win_link]

[![Build Status][travis_status]][travis_link]
[![Build Status][appveyor_status]][appveyor_link]

[docker_status]: https://github.com/Mizux/dotnet-native/workflows/Docker/badge.svg?branch=main
[docker_link]: https://github.com/Mizux/dotnet-native/actions?query=workflow%3A"Docker"
[linux_svg]: https://github.com/Mizux/dotnet-native/workflows/Linux/badge.svg?branch=main
[linux_link]: https://github.com/Mizux/dotnet-native/actions?query=workflow%3A"Linux"
[osx_svg]: https://github.com/Mizux/dotnet-native/workflows/MacOS/badge.svg?branch=main
[osx_link]: https://github.com/Mizux/dotnet-native/actions?query=workflow%3A"MacOS"
[win_svg]: https://github.com/Mizux/dotnet-native/workflows/Windows/badge.svg?branch=main
[win_link]: https://github.com/Mizux/dotnet-native/actions?query=workflow%3A"Windows"

[travis_status]: https://travis-ci.com/Mizux/dotnet-native.svg?branch=main
[travis_link]: https://travis-ci.com/Mizux/dotnet-native

[appveyor_status]: https://ci.appveyor.com/api/projects/status/q105jch2jxxb5t4f/branch/master?svg=true
[appveyor_link]: https://ci.appveyor.com/project/Mizux/dotnet-native/branch/main

# Introduction

This project aim to explain how you build a .NetStandard2.0 native (for win-x64, linux-x64 and osx-x64) nuget multiple package using [`.NET Core CLI`](https://docs.microsoft.com/en-us/dotnet/core/tools/) and the [*new* .csproj format](https://docs.microsoft.com/en-us/dotnet/core/tools/csproj).  
e.g. You have a cross platform C++ library (using a CMake based build) and a .NetStandard2.0 wrapper on it thanks to SWIG.  
Then you want to provide a cross-platform Nuget package to consume it in a .NetCoreApp2.1 project...

## Table of Content

* [Requirement](#requirement)
* [Directory Layout](#directory-layout)
* [Build Process](#build-process)
  * [Local Mizux.DotnetNative Package](#local-mizuxfoo-package)
    * [Building a runtime Mizux.DotnetNative Package](#building-local-runtime-mizuxfoo-package)
    * [Building a Local Mizux.DotnetNative Package](#building-local-mizuxfoo-package)
    * [Testing the Local Mizux.DotnetNative Package](#testing-local-mizuxfoo-package)
  * [Complete Mizux.DotnetNative Package](#complete-mizuxfoo-package)
    * [Building all runtime Mizux.DotnetNative Package](#building-all-runtime-mizuxfoo-package)
    * [Building a Complete Mizux.DotnetNative Package](#building-complete-mizuxfoo-package)
    * [Testing the Complete Mizux.DotnetNative Package](#testing-complete-mizuxfoo-package)
* [Appendices](#appendices)
  * [Resources](#resources)
  * [Issues](#issues)
* [Misc](#misc)

## Requirement

You'll need the ".Net Core SDK >= 2.1.302" to get the dotnet cli.
i.e. We won't/can't rely on VS 2019 since we want a portable cross-platform [`dotnet/cli`](https://github.com/dotnet/cli) pipeline. 

## Directory Layout

The project layout is as follow:

* [CMakeLists.txt](CMakeLists.txt) Top-level for [CMake](https://cmake.org/cmake/help/latest/) based build.
* [cmake](cmake) Subsidiary CMake files.
  * [dotnet.cmake](cmake/dotnet.cmake) All internall .Net CMake stuff.

* [Foo](Foo) Root directory for `Foo` library.
  * [CMakeLists.txt](Foo/CMakeLists.txt) for `Foo`.
  * [include](Foo/include) public folder.
    * [foo](Foo/include/foo)
      * [Foo.hpp](Foo/include/foo/Foo.hpp)
  * [dotnet](Foo/dotnet)
    * [CMakeLists.txt](Foo/dotnet/CMakeLists.txt) for `Foo` .Net.
    * [foo.i](Foo/dotnet/foo.i) SWIG .Net wrapper.
  * [src](Foo/src) private folder.
    * [src/Foo.cpp](Foo/src/Foo.cpp)

* [dotnet](dotnet) Root directory for .Net template files
  * [`Mizux.DotnetNative.runtime.csproj.in`](dotnet/Mizux.DotnetNative.runtime.csproj.in) csproj template for the .Net "native" (i.e. RID dependent) package.
  * [`Mizux.DotnetNative.csproj.in`](dotnet/Mizux.DotnetNative.csproj.in) csproj template for the .Net package.
  * [`Test.csproj.in`](dotnet/Test.csproj.in) csproj template for .Net test project.
  * [`Sample.csproj.in`](dotnet/Sample.csproj.in) csproj template for .Net sample project.

* [tests](tests) Root directory for tests
  * [CMakeLists.txt](tests/CMakeLists.txt) for `DotnetNative.Test` .Net.
  * [`FooTests.cs`](tests/FooTests.cs) Code of the Mizux.DotnetNative.FooTests project.

* [samples](samples) Root directory for samples
  * [CMakeLists.txt](samples/CMakeLists.txt) for `DotnetNative.FooApp` .Net.
  * [`FooApp.cs`](samples/FooApp.cs) Code of the `DotnetNative.FooApp` app.

* [ci](ci) Root directory for continuous integration.

## Build Process

To Create a native dependent package we will split it in two parts:

* A bunch of `Mizux.DotnetNative.runtime.{rid}.nupkg` packages for each 
[Runtime Identifier (RId)](https://docs.microsoft.com/en-us/dotnet/core/rid-catalog) targeted containing the native libraries.
* A generic package `Mizux.DotnetNative.nupkg` depending on each runtime packages and
containing the managed .Net code.
Actually, You don't need a specific variant of .Net Standard wrapper, simply omit the library extension and .Net magic will pick
the correct native library.  
ref: https://www.mono-project.com/docs/advanced/pinvoke/#library-names

note: [`Microsoft.NetCore.App` packages](https://www.nuget.org/packages?q=Microsoft.NETCore.App)
follow this layout.

note: While Microsoft use `runtime-<rid>.Company.Project` for native package naming,
it is very difficult to get ownership on it, so you should prefer to use`Company.Project.runtime-<rid>` instead since you can have ownership on `Company.*` prefix more easily.

We have two use case scenario:
1. Locally, be able to build a Mizux.DotnetNative package which **only** target the local `OS Platform`,
i.e. building for only one 
[Runtime Identifier (RID)](https://docs.microsoft.com/en-us/dotnet/core/rid-catalog).  
note: This is usefull when the C++ build is a complex process for Windows, Linux and MacOS.  
i.e. You don't support cross-compilation for the native library.

2. Be able to create a complete cross-platform (ed. platform as multiple rid) Mizux.DotnetNative package.  
i.e. First you generate each native Nuget package (`Mizux.DotnetNative.runtime.{rid}.nupkg`) 
on each native architecture, then copy paste these artifacts on one native machine
to generate the meta-package `Mizux.DotnetNative`.

### Local Mizux.DotnetNative Package

Let's start with scenario 1: Create a *Local only* `Mizux.DotnetNative.nupkg` package targeting **one** [Runtime Identifier (RID)](https://docs.microsoft.com/en-us/dotnet/core/rid-catalog).  
We would like to build a `Mizux.DotnetNative.nupkg` package which only depends on one `Mizux.DotnetNative.runtime.{rid}.nupkg` in order to dev/test locally.  

The pipeline for `linux-x64` should be as follow:  
note: The pipeline will be similar for `osx-x64` and `win-x64` architecture, don't hesitate to look at the CI log.
![Local Pipeline](doc/local_pipeline.svg)
![Legend](doc/legend.svg)

#### Building local runtime Mizux.DotnetNative Package

disclaimer: In this git repository, we use `CMake` and `SWIG`.  
Thus we have the C++ shared library `libFoo.so` and the SWIG generated .Net wrapper `Foo.cs`.  
note: For a C++ CMake cross-platform project sample, take a look at [Mizux/cmake-cpp](https://github.com/Mizux/cmake-cpp).   
note: For a C++/Swig CMake cross-platform project sample, take a look at [Mizux/cmake-swig](https://github.com/Mizux/cmake-swig). 

So first let's create the local `Mizux.DotnetNative.runtime.{rid}.nupkg` nuget package.

Here some dev-note concerning this `Mizux.DotnetNative.runtime.{rid}.csproj`.
* Once you specify a `RuntimeIdentifier` then `dotnet build` or `dotnet build -r {rid}` 
will behave identically (save you from typing it).
  * note: it is **NOT** the case if you use `RuntimeIdentifiers` (notice the 's')
* It is [recommended](https://docs.microsoft.com/en-us/nuget/create-packages/native-packages)
to add the tag `native` to the 
[nuget package tags](https://docs.microsoft.com/en-us/dotnet/core/tools/csproj#packagetags)
  ```xml
  <PackageTags>native</PackageTags>
  ```
* This package is a runtime package so we don't want to ship an empty assembly file:
  ```xml
  <IncludeBuildOutput>false</IncludeBuildOutput>
  ```
* Add the native (i.e. C++) libraries to the nuget package in the repository `runtimes/{rid}/native`. e.g. for linux-x64:
  ```xml
  <Content Include="*.so">
    <PackagePath>runtimes/linux-x64/native/%(Filename)%(Extension)</PackagePath>
    <Pack>true</Pack>
    <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
  </Content>
  ```
* Generate the runtime package to a defined directory (i.e. so later in Mizux.DotnetNative package we will be able to locate it)
  ```xml
  <PackageOutputPath>{...}/packages</PackageOutputPath>
  ```

Then you can generate the package using:
```bash
dotnet pack Mizux.DotnetNative.runtime.{rid}
```
note: this will automatically trigger the `dotnet build`.

If everything good the package (located where your `PackageOutputPath` was defined) should have this layout:
```
{...}/packages/Mizux.DotnetNative.runtime.{rid}.nupkg:
\- Mizux.DotnetNative.runtime.{rid}.nuspec
\- runtimes
   \- {rid}
      \- native
         \- *.so / *.dylib / *.dll
... 
```
note: `{rid}` could be `linux-x64` and `{framework}` could be `netstandard2.0`

tips: since nuget package are zip archive you can use `unzip -l <package>.nupkg` to study their layout.

#### Building local Mizux.DotnetNative Package

So now, let's create the local `Mizux.DotnetNative.nupkg` nuget package which will depend on our previous runtime package.

Here some dev-note concerning this `DotnetNative.csproj`.
* Add the previous package directory:
  ```xml
  <RestoreSources>{...}/packages;$(RestoreSources)</RestoreSources>
  ```
* Add dependency (i.e. `PackageReference`) on each runtime package(s) availabe:
  ```xml
  <ItemGroup>
    <RuntimeLinux Include="{...}/packages/Mizux.DotnetNative.runtime.linux-x64.*.nupkg"/>
    <RuntimeOsx   Include="{...}/packages/Mizux.DotnetNative.runtime.osx-x64.*.nupkg"/>
    <RuntimeWin   Include="{...}/packages/Mizux.DotnetNative.runtime.win-x64.*.nupkg"/>
    <PackageReference Include="Mizux.DotnetNative.runtime.linux-x64" Version="1.0" Condition="Exists('@(RuntimeLinux)')"/>
    <PackageReference Include="Mizux.DotnetNative.runtime.osx-x64"   Version="1.0" Condition="Exists('@(RuntimeOsx)')"  />
    <PackageReference Include="Mizux.DotnetNative.runtime.win-x64"   Version="1.0" Condition="Exists('@(RuntimeWin)')"  />
  </ItemGroup>
  ```
  Thanks to the `RestoreSource` we can work locally we our just builded package
  without the need to upload it on [nuget.org](https://www.nuget.org/).

Then you can generate the package using:
```bash
dotnet pack Mizux.DotnetNative
```

If everything good the package (located where your `PackageOutputPath` was defined) should have this layout:
```
{...}/packages/Mizux.DotnetNative.nupkg:
\- Mizux.DotnetNative.nuspec
\- lib
   \- {framework}
      \- Mizux.DotnetNative.dll
... 
```
note: `{framework}` could be `netstandard2.0` or/and `netstandard2.1`

#### Testing local Mizux.DotnetNative.FooApp Package

We can test everything is working by using the `Mizux.DotnetNative.FooApp` or `Mizux.DotnetNative.FooTests` project.

First you can build it using:
```
dotnet build <build_dir>/dotnet/FooApp
```
note: Since `Mizux.DotnetNative.FooApp` `PackageReference` Mizux.DotnetNative and add `{...}/packages` to the `RestoreSource`.
During the build of DotnetNative.FooApp you can see that `Mizux.DotnetNative` and
`Mizux.DotnetNative.runtime.{rid}` are automatically installed in the nuget cache.

Then you can run it using:
```
dotnet run --project <build_dir>/dotnet/FooApp/FooApp.csproj
```
note: Contrary to `dotnet build` and `dotnet pack` you must use `--project`
before the `.csproj` path (let's call it "dotnet cli command consistency")

You should see:
```sh
$ dotnet run --project build/dotnet/FooApp/FooApp.csproj
[1] Enter DotnetNativeApp
[2] Enter Foo::staticFunction(int)
[3] Enter freeFunction(int)
[3] Exit freeFunction(int)
[2] Exit Foo::staticFunction(int)
[1] Exit DotnetNativeApp
```

### Complete Mizux.DotnetNative Package
Let's start with scenario 2: Create a *Complete* `Mizux.DotnetNative.nupkg` package targeting multiple [Runtime Identifier (RID)](https://docs.microsoft.com/en-us/dotnet/core/rid-catalog).  
We would like to build a `Mizux.DotnetNative.nupkg` package which depends on several `Mizux.DotnetNative.runtime.{rid}.nupkg`.  

The pipeline should be as follow:  
note: This pipeline should be run on any architecture,
provided you have generated the three architecture dependent `Mizux.DotnetNative.runtime.{rid}.nupkg` nuget packages.
![Full Pipeline](doc/full_pipeline.svg)
![Legend](doc/legend.svg)

#### Building All runtime Mizux.DotnetNative Package

Like in the previous scenario, on each targeted OS Platform you can build the coresponding
`Mizux.DotnetNative.runtime.{rid}.nupkg` package.

Simply run on each platform
```bash
cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
```
note: replace `{rid}` by the Runtime Identifier associated to the current OS platform.

Then on one machine used, you copy all other packages in the `{...}/packages` so
when building `Mizux.DotnetNative.csproj` we can have access to all package...

#### Building Complete Mizux.DotnetNative Package

This is the same step than in the previous scenario, since we "see" all runtime
packages in `{...}/packages`, the project will depends on each of them.

Once copied all runtime package locally, simply run:
```bash
dotnet build <build_dir>/dotnet/Mizux.DotnetNative
dotnet pack <build_dir>/dotnet/Mizux.DotnetNative
```

#### Testing Complete Mizux.DotnetNative Package

We can test everything is working by using the `Mizux.DotnetNative.FooApp` or `Mizux.DotnetNative.FooTests` project.

First you can build it using:
```
dotnet build <build_dir>/dotnet/FooApp
```
note: Since Mizux.DotnetNative.FooApp `PackageReference` Mizux.DotnetNative and add `{...}/packages` to the `RestoreSource`.
During the build of Mizux.DotnetNative.FooApp you can see that `Mizux.DotnetNative` and
`Mizux.DotnetNative.runtime.{rid}` are automatically installed in the nuget cache.

Then you can run it using:
```
dotnet run --project <build_dir>/dotnet/FooApp/FooApp.csproj
```

You should see something like this
```bash
$ dotnet run --project build/dotnet/FooApp/FooApp.csproj
[1] Enter DotnetNativeApp
[2] Enter Foo::staticFunction(int)
[3] Enter freeFunction(int)
[3] Exit freeFunction(int)
[2] Exit Foo::staticFunction(int)
[1] Exit DotnetNativeApp
```

## Appendices

Few links on the subject...

### Resources

* [.NET Core RID Catalog](https://docs.microsoft.com/en-us/dotnet/core/rid-catalog)
* [Creating native packages](https://docs.microsoft.com/en-us/nuget/create-packages/native-packages)
* [Blog on Nuget Rid Graph](https://natemcmaster.com/blog/2016/05/19/nuget3-rid-graph/)

* [Common MSBuild project properties](https://docs.microsoft.com/en-us/visualstudio/msbuild/common-msbuild-project-properties?view=vs-2017)
* [MSBuild well-known item metadata](https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-well-known-item-metadata?view=vs-2017)
* [Additions to the csproj format for .NET Core](https://docs.microsoft.com/en-us/dotnet/core/tools/csproj)

### Issues

Some issue related to this process
* [Nuget needs to support dependencies specific to target runtime #1660](https://github.com/NuGet/Home/issues/1660)
* [Improve documentation on creating native packages #238](https://github.com/NuGet/docs.microsoft.com-nuget/issues/238)
* [Guide for packaging C# library using P/Invoke](https://github.com/NuGet/Home/issues/8623)

## Misc

Image has been generated using [plantuml](http://plantuml.com/):
```bash
plantuml -Tsvg doc/{file}.dot
```
So you can find the dot source files in [doc](doc).

## License

Apache 2. See the LICENSE file for details.

## Disclaimer

This is not an official Google product, it is just code that happens to be
owned by Google.
