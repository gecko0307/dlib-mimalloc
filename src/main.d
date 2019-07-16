module main;

import std.stdio;

import std.stdio;
import bindbc.mimalloc;
import dlib.core.memory;
import mimallocator;

class Foo
{
    int x;

    this(int x)
    {
        this.x = x;
    }
}

void main()
{
    loadMimalloc();
    globalAllocator = Mimallocator.instance();

    Foo[] arr = New!(Foo[])(10000000);
    writeln(arr.length);

    foreach(i, v; arr)
    {
        arr[i] = New!Foo(cast(int)i);
    }

    foreach(i, v; arr)
    {
        Delete(arr[i]);
    }
}
