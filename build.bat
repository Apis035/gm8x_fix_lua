@set out=gm8x_fix_lua
@echo Building %out%.exe ...

@(
    lua build\squish
    del a.lua
    ren a.lua.uglified a.lua
    build\glue build\srlua.exe a.lua %out%.exe
    del a.lua
)>nul