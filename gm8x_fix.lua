--[[ Requires ]]--

require "patch_types"
require "util"

local patchList = require "patches"

--[[ Split functions ]]--

local function can_patch(file, patches)
    local patched, unpatched = true, true
    local char

    for _,patch in ipairs(patches) do
        file:seek("set", patch.pos)
        char = file:read(1)
        if char ~= patch.newByte  then   patched = false end
        if char ~= patch.origByte then unpatched = false end
    end

    if   patched then return PatchState.DONE end
    if unpatched then return PatchState.ABLE end
                      return PatchState.UNFOUND
end

local function patch_exe(file, patches)
    for _,patch in ipairs(patches) do
        file:seek("set", patch.pos)
        file:write(patch.newByte)
    end
end

local function printHelp()
    print(table.concat({
        "Usage: " .. arg[0] .. " file [options]",
        "        or drag the game file into the patcher.",
        "",
        "  -h    print this help",
        "  -nb   disable backup",
        "  -ni   disable input lag patch",
        "  -nj   disable joystick patch",
        "  -ns   disable scheduler patch",
        "  -nr   disable display reset patch",
        "  -nm   disable memory patch",
        "  -nd   disable DirectPlay Patch]]"}, "\n"
    ))
end

--[[ Main program ]]--

local filename, silent, makeBackup = nil, false, true
local patchDisabled = {}

-- Parse arguments
for i=1, #arg do
    local arg = arg[i]

        if arg == "-h"  then printHelp() exit()
    elseif arg == "-s"  then silent     = true
    elseif arg == "-nb" then makeBackup = false
    elseif arg == "-nj" then patchDisabled[PatchType.JOY]      = true
    elseif arg == "-nm" then patchDisabled[PatchType.MEM]      = true
    elseif arg == "-nd" then patchDisabled[PatchType.DPLAY]    = true
    elseif arg == "-ns" then patchDisabled[PatchType.SCHED]    = true
    elseif arg == "-ni" then patchDisabled[PatchType.INPUTLAG] = true
    elseif arg == "-nr" then patchDisabled[PatchType.RESET]    = true

    -- Select the lastest inputted file if multiple file is specified
    else filename = arg end
end

-- Check if user disabled all patches
local allDisabled = true

for i=1, #PatchType do
    if patchDisabled[i] ~= true then
        allDisabled = false
        break
    end
end

if allDisabled then
    print "All patch is disabled, no operation will be performed. Closing..."
    exit()
end

-- No file specified
if filename == nil then
    print "No file is specified."
    printHelp()
    exit()
end

-- Check input file
print("Inspecting file %s", filename)

local file, msg = io.open(filename, "r+b")

-- File not loaded
if file == nil then
    print("Could not open file (%s).", msg)
    exit()
end

-- No MZ header
if file:read(2) ~= "MZ" then
    print "This is not an executable file."
    exit()
end

local hasAppliedPatch, canApplyPatch = false, false

for _,patch in pairs(patchList) do
    patch.state = can_patch(file, patch.bytes)

    if patchDisabled[patch.type] and patch.state == PatchState.ABLE then
        patch.state = PatchState.UNFOUND
    end

    if patch.state == PatchState.ABLE then
        canApplyPatch = true
    elseif patch.state == PatchState.DONE then
        hasAppliedPatch = true
    end
end

-- Can't find compatible patches
if not canApplyPatch and not hasAppliedPatch then
    print "This game cannot be patched. It may not be a GameMaker 7.0, 8.0, or 8.1 game."
    file:close()
    exit()
end

-- Patch has been applied
if hasAppliedPatch then
    print "Patches already applied:"
    for _,patch in pairs(patchList) do
        if patch.state == PatchState.DONE then
            print(" * %s", patch.name)
        end
    end
end

-- Patch can be applied
if canApplyPatch then
    print "Patches that can be applied:"
    for _,patch in pairs(patchList) do
        if patch.state == PatchState.ABLE then
            print(" * %s", patch.name)
        end
    end
else
    -- All patch has been applied
    print "No new patches can be applied."
    file:close()
    exit()
end

-- Backup file
if makeBackup then
    print "Backup will be made before applying patches."
    write "Press Enter to continue..."
    wait()

    local backupFilename  = filename .. '.bak'
    local backupFileExist = io.open(backupFilename, "rb")
    local doBackup        = backupFileExist == nil

    if backupFileExist then
        backupFileExist:close()

        print("Previous backup file exist on %s", backupFilename)

        doBackup = prompt "Do you want to overwrite backup file?"     -- If yes return true
            or not prompt "Continue applying patches without backup?" -- If yes return false
               and exit()                                             -- No backup and no continue
    end

    if doBackup then
        os.execute("copy " .. filename .. " " .. backupFilename)
    end
end

-- Apply patches
file = io.open(filename, "r+b")
local joyPatched = false

for _,patch in ipairs(patchList) do
    if patch.type == PatchType.JOY and patch.state == PatchState.DONE then
        joyPatched = true
    end

    if patch.state == PatchState.ABLE then
        if patch.type == PatchType.SCHED and not joyPatched then
            print "It looks like the joystick patch wasn't applied."
            print "It's best to apply that if you're going to use the scheduler patch."
        end

        if prompt("Apply %s?", patch.name) then
            patch_exe(file, patch.bytes)
            if patch.type == PatchType.JOY then
                joyPatched = true
            end
        end
    end
end

file:close()
print "All done!"

exit(0)