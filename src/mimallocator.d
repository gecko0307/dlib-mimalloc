module mimallocator;

import core.exception;
import std.algorithm.comparison;
import bindbc.mimalloc;
import dlib.memory.allocator;

class Mimallocator : Allocator
{
    void[] allocate(size_t size)
    {
        if (!size)
        {
           return null;
        }
        auto p = mi_malloc(size);

        if (!p)
        {
           onOutOfMemoryError();
        }
        return p[0..size];
    }

    bool deallocate(void[] p)
    {
        if (p !is null)
        {
            mi_free(p.ptr);
        }
        return true;
    }

    bool reallocate(ref void[] p, size_t size)
    {
        if (!size)
        {
            deallocate(p);
            p = null;
            return true;
        }
        else if (p is null)
        {
            p = allocate(size);
            return true;
        }
        auto r = mi_realloc(p.ptr, size);

        if (!r)
        {
            onOutOfMemoryError();
        }
        p = r[0..size];

        return true;
    }

    @property immutable(uint) alignment() const
    {
        return cast(uint) max(double.alignof, real.alignof);
    }

    static @property Mimallocator instance() @nogc nothrow
    {
        if (instance_ is null)
        {
            immutable size = __traits(classInstanceSize, Mimallocator);
            void* p = mi_malloc(size);

            if (p is null)
            {
                onOutOfMemoryError();
            }
            p[0..size] = typeid(Mimallocator).initializer[];
            instance_ = cast(Mimallocator) p[0..size].ptr;
        }
        return instance_;
    }

    private static __gshared Mimallocator instance_;
}
