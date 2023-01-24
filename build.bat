@echo Building gm8fix.exe ...

@(
    lua build\squish
    del a.lua
    ren a.lua.uglified a.lua
    build\glue build\srlua.exe a.lua gm8fix.exe
    del a.lua
)>nul