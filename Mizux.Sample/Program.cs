using System;

namespace Example {
  class Program {
    static void Main(string[] args) {
      int level = 1;
      Console.WriteLine($"[{level}] Enter Example");
      Foo.Foo.Hello(level+1);
      Console.WriteLine($"[{level}] Exit Example");
    }
  }
}
