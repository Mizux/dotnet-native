using System;

namespace Foo {
  public class Native {
    public static void Internal(int level) {
      Console.WriteLine($"[{level}] Enter Foo.linux-x64");
      Console.WriteLine($"[{level}] Exit Foo.linux-x64");
    }
  }
}
