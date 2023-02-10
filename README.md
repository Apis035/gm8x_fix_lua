# gm8x_fix_lua
**gm8x_fix_lua** is a Lua implementation of [gm8x_fix](https://github.com/skyfloogle/gm8x_fix) from C language. Originally created by [skyfloogle](https://github.com/skyfloogle).

**gm8x_fix** is patcher that fixes issues in games made with Game Maker 7.0, 8.0, and 8.1.

This was created as an exercise for me to write Lua code and understanding how Lua works. The translated Lua code are not all identical to the C code, some of the algorithms in original C code are changed to use the features of Lua.

# Running
Download the binary release from [Releases](https://github.com/apis035/gm8x_fix_lua/releases) tab.

If you want to run directly from source code:

```batch
> lua gm8x_fix.lua
```

Assuming you have Lua installed and is accessible from PATH environment. Tested with Lua 5.1.5.

# How to use
Drag your game executable file into *gm8x_fix_lua.exe* and follow the instructions displayed on the console screen. For any asked questions, answer with `y` or `n` (yes/no).

You can also run it from command line with these options:
- `-h` show help (showed by default if run without arguments)
- `-s` enable silent mode
- `-nb` disable backup
- `-ni` disable input lag patch
- `-nj` disable joystick patch
- `-ns` disable scheduler patch
- `-nr` disable display reset patch
- `-nm` disable memory patch
- `-nd` disable DirectPlay patch

Silent mode will not print any information to the console and will apply any available patches. Use the `-n*` option to disable certain patch. This is useful for automating patching.

See the [original project](https://github.com/skyfloogle/gm8x_fix)'s description for further explanation on what this patcher does.

# Building executable
Run `build.bat` and it will generate `gm8x_fix_lua.exe`.

Tools used for building executable:
- [squish](http://code.matthewwild.co.uk/squish) - Combine mutiple lua scripts into a single file.
- [srlua](https://web.tecgraf.puc-rio.br/~lhf/ftp/lua/#srlua) - Building self-running Lua program.