using System;

using Mizux.Foo;

namespace FooApp {
  class Program {
    static void Main(string[] args) {
      int level = 1;
      Console.WriteLine($"[{level}] Enter FooApp");
      Foo.Hello(level+1);
      Console.WriteLine($"[{level}] Exit FooApp");
    }
  }
}
