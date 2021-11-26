using System;
using Mizux.DotnetNative.Bar;
using Mizux.DotnetNative.Foo;
using Mizux.DotnetNative.FooBar;

namespace Mizux.DotnetNative.FooApp {
  class Program {
    static void Main(string[] args) {
      int level = 1;
      Console.WriteLine($"[{level}] Enter Example");
      Bar.Bar.StaticFunction(level+1);
      Console.WriteLine($"[{level}] Exit Example");

      level = 1;
      Console.WriteLine($"[{level}] Enter Example");
      Foo.Foo.StaticFunction(level+1);
      Console.WriteLine($"[{level}] Exit Example");

      level = 1;
      Console.WriteLine($"[{level}] Enter Example");
      FooBar.FooBar.StaticFunction(level+1);
      Console.WriteLine($"[{level}] Exit Example");
    }
  }
}
