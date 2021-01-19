using System;
using Mizux.DotnetNative;

namespace Mizux.DotnetNative.Sample {
  class Program {
    static void Main(string[] args) {
      int level = 1;
      Console.WriteLine($"[{level}] Enter FooApp");
      Foo.StaticFunction(level+1);
      Console.WriteLine($"[{level}] Exit FooApp");
    }
  }
}
