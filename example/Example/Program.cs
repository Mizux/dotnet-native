using System;

namespace Example {
  class Program {
    static void Main(string[] args) {
      int level = 1;
      Console.WriteLine($"[{level}] Enter Example");
      Foo.Native.Internal(level+1);
      Console.WriteLine($"[{level}] Exit Example");
    }
  }
}
