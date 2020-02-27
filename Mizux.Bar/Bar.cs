using System;

namespace Bar {
  public class Bar {
    public static void StaticCall(int level) {
      Console.WriteLine($"[{level}] Enter Bar");
      Console.WriteLine($"[{level}] Exit Bar");
    }
  }
}
