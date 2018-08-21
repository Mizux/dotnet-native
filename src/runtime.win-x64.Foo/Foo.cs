using System;

namespace Foo {
    public class Foo {
        public static void Hello(int level) {
            Console.WriteLine($"[{level}] Enter Foo");
            Native.Internal(level+1);
            Console.WriteLine($"[{level}] Exit Foo");
        }
    }
}
