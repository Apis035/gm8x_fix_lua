# gm8x_fix_lua
A patcher that fixes certain issues in games made with Game Maker 7.0, 8.0, and 8.1. gm8x_fix_lua is a traslation of [skyfloogle](https://github.com/skyfloogle)'s [gm8x_fix](https://github.com/skyfloogle/gm8x_fix) from C language to Lua language.

This was created as an exercise for me to learn how to write Lua code and understanding how Lua works. The translated Lua code are not all identical to the C code, some of the algorithms in original C code are altered/simplified to fit into or use the features of Lua.

# Running
Download the binary release from [Releases](https://github.com/apis035/gm8x_fix_lua/releases) tab.

If you want to run directly from source code:

`lua gm8x_fix.lua`

Assuming you have Lua installed and accessible from PATH environment. Tested with Lua 5.1.1.

# How to use
Drag your game executable file into gm8x_fix_lua.exe and follow the instructions displayed on the console screen. Any asked questions simply enter `y` or `n` (yes/no) for your answer according to the question.

You can also run it from command line with these options:
- `-h` show help (showed by default if you run without arguments)
- `-nb` disable backup.
- `-ni` disable input lag patch
- `-nj` disable joystick patch
- `-ns` disable scheduler patch
- `-nr` disable display reset patch
- `-nm` disable memory patch
- `-nd` disable DirectPlay patch

The command line method are currently useless as there no silent mode option (will be implemented later), as it is supposed to automating patching without further input from the user for applying individual patch.

See the [original project](https://github.com/skyfloogle/gm8x_fix)'s description for further explanation on what this patcher does.

# Building executable
Run `build.bat` and it will generate `gm8x_fix_lua.exe`.

The tools included in `build` folder are:
- [squish](https://github.com/LuaDist/squish) - Combine mutiple lua scripts into a single file.
- [srlua](https://github.com/LuaDist/srlua) - Self-running Lua interpreter.
- glue - Combine srlua and lua script into executable.