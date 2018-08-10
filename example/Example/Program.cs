using System;
using Foo;

namespace Example {
  class Program {
    static void Main(string[] args) {
      Console.WriteLine("Hello from Example!");
      Console.WriteLine("Calling Foo:...");
      Foo.Foo.Hello();
      Console.WriteLine("Calling Foo:...DONE");
    }
  }
}
