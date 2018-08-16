using System;

namespace BarApp {
  class Program {
    static void Main(string[] args) {
      int level = 1;
      Console.WriteLine($"[{level}] Enter BarApp");
      Bar.Bar.StaticCall(level+1);
      Console.WriteLine($"[{level}] Exit BarApp");
    }
  }
}
