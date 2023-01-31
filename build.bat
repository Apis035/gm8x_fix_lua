@echo off
set out=gm8x_fix_lua
echo Building %out%.exe ...

if not exist build\squish.exe (
    cd build
    glue srlua.exe squish squish.exe
    cd ..
)

build\squish
ren a.lua.uglified a
build\glue build\srlua.exe a %out%.exe
del a.lua a