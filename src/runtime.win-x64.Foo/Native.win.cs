using System;

namespace Foo {
  public class Native {
    public static void Internal(int level) {
      Console.WriteLine($"[{level}] Enter Foo.win-x64");
      Console.WriteLine($"[{level}] Exit Foo.win-x64");
    }
  }
}
