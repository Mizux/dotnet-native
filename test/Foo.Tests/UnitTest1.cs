using System;
using Xunit;

namespace FooTests {
    public class UnitTest1 {
        [Fact]
        public void Test1() {
          int level = 1;
          Console.WriteLine($"[{level}] Enter UnitTest1");
          Foo.Foo.Hello(level+1);
          Console.WriteLine($"[{level}] Exit UnitTest1");
        }
    }
}
