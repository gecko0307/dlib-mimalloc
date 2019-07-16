module bindbc.mimalloc;

import bindbc.loader;

enum MimallocSupport {
    noLibrary,
    badLibrary,
    mimalloc105
}

extern(C) @nogc nothrow
{
    alias da_mi_malloc = void* function(size_t size);
    alias da_mi_calloc = void* function(size_t count, size_t size);
    alias da_mi_realloc = void* function(void* p, size_t newsize);
    alias da_mi_expand = void* function(void* p, size_t newsize);
    alias da_mi_free = void function(void* p);
    alias da_mi_strdup = char* function(const char* s);
    alias da_mi_strndup = char* function(const char* s, size_t n);
    alias da_mi_realpath = char* function(const char* fname, char* resolved_name);
}

__gshared
{
    da_mi_malloc mi_malloc;
    da_mi_calloc mi_calloc;
    da_mi_realloc mi_realloc;
    da_mi_expand mi_expand;
    da_mi_free mi_free;
    da_mi_strdup mi_strdup;
    da_mi_strndup mi_strndup;
    da_mi_realpath mi_realpath;
}

private
{
    SharedLib lib;
    MimallocSupport loadedVersion;
}

void unloadMimalloc()
{
    if (lib != invalidHandle)
    {
        lib.unload();
    }
}

MimallocSupport loadedMimallocVersion() { return loadedVersion; }
bool isMimallocLoaded() { return lib != invalidHandle; }

MimallocSupport loadMimalloc()
{
    version(Windows)
    {
        const(char)[][2] libNames =
        [
            "mimalloc.dll",
            "mimalloc-override.dll"
        ];
    }
    else version(OSX)
    {
        const(char)[][1] libNames =
        [
            "mimalloc.dylib"
        ];
    }
    else version(Posix)
    {
        const(char)[][2] libNames =
        [
            "libmimalloc.so.6",
            "libmimalloc.so"
        ];
    }
    else static assert(0, "mimalloc is not yet supported on this platform.");

    MimallocSupport ret;
    foreach(name; libNames)
    {
        ret = loadMimalloc(name.ptr);
        if (ret != MimallocSupport.noLibrary)
            break;
    }
    return ret;
}

MimallocSupport loadMimalloc(const(char)* libName)
{
    lib = load(libName);
    if(lib == invalidHandle)
    {
        return MimallocSupport.noLibrary;
    }

    auto errCount = errorCount();
    loadedVersion = MimallocSupport.badLibrary;

    lib.bindSymbol(cast(void**)&mi_malloc, "mi_malloc");
    lib.bindSymbol(cast(void**)&mi_calloc, "mi_calloc");
    lib.bindSymbol(cast(void**)&mi_realloc, "mi_realloc");
    lib.bindSymbol(cast(void**)&mi_expand, "mi_expand");
    lib.bindSymbol(cast(void**)&mi_free, "mi_free");
    lib.bindSymbol(cast(void**)&mi_strdup, "mi_strdup");
    lib.bindSymbol(cast(void**)&mi_strndup, "mi_strndup");
    lib.bindSymbol(cast(void**)&mi_realpath, "mi_realpath");

    loadedVersion = MimallocSupport.mimalloc105;

    if (errorCount() != errCount)
        return MimallocSupport.badLibrary;

    return loadedVersion;
}
