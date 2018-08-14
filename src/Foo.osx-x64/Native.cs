using System;

namespace Foo {
  public class Native {
    public static void Internal(int level) {
      Console.WriteLine($"[{level}] Enter Foo.osx-x64");
      Console.WriteLine($"[{level}] Exit Foo.osx-x64");
    }
  }
}
