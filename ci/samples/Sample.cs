using System;
using Mizux.DotnetNative.Bar;
using Mizux.DotnetNative.Foo;
using Mizux.DotnetNative.FooBar;

namespace Mizux.DotnetNative.FooApp {
  class Program {
    static void Main(string[] args) {
      int level = 1;
      Console.WriteLine($"[{level}] Enter Sample");
      Bar.Bar.StaticFunction(level+1);
      Console.WriteLine($"[{level}] Exit Sample");

      level = 1;
      Console.WriteLine($"[{level}] Enter Sample");
      Foo.Foo.StaticFunction(level+1);
      Console.WriteLine($"[{level}] Exit Sample");

      level = 1;
      Console.WriteLine($"[{level}] Enter Sample");
      FooBar.FooBar.StaticFunction(level+1);
      Console.WriteLine($"[{level}] Exit Sample");
    }
  }
}
