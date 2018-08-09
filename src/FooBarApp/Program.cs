using System;
using Foo;
using Bar;

namespace FooBar {
  class Program {
    static void Main(string[] args) {
      Console.WriteLine("Hello from FooBar!");
      Foo.Foo.Hello();
      Bar.Bar.Hello();
    }
  }
}
