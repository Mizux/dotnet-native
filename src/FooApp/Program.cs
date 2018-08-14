using System;

namespace FooApp {
  class Program {
    static void Main(string[] args) {
      int level = 1;
      Console.WriteLine($"[{level}] Enter FooApp");
      Foo.Foo.Hello(level+1);
      Console.WriteLine($"[{level}] Exit FooApp");
    }
  }
}
