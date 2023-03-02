--| Requires |------------------------------------------------------------------

require "patch_types"

--| Split functions |-----------------------------------------------------------

local write, wait, exit = io.write, io.read, os.exit

local function concat(t)
    return table.concat(t, "\n")
end

local function print(str, ...)
    _G.print(tostring(str):format(...))
end

local function prompt(msg, ...)
    local char
    repeat
        io.write((msg .. " [y/n] "):format(...))
        char = string.lower(io.read())
    until char == 'y' or char == 'n'
    return char == 'y'
end

local function check_patch(file, patches)
    local char
    local patched, unpatched = true, true
    for _,patch in ipairs(patches) do
        file:seek("set", patch.pos)
        char = file:read(1)
        if char ~= patch.newByte  then   patched = false end
        if char ~= patch.origByte then unpatched = false end
    end
    return patched and PatchState.DONE or
         unpatched and PatchState.ABLE or
                       PatchState.UNFOUND
end

local function patch_exe(file, patches)
    for _,patch in ipairs(patches) do
        file:seek("set", patch.pos)
        file:write(patch.newByte)
    end
end

local titleBox = concat {
    "+-----------------------------------------+",
    "| gm8x_fix_lua v0.2 -- Feb 6th 2023       |",
    "| https://github.com/Apis035/gm8x_fix_lua |",
    "+-----------------------------------------+",
    "",
}

local help = concat {
    "Usage: " .. arg[0] .. " file [options]",
    "        or drag the game file into the patcher.",
    "",
    "  -h    print this help",
    "  -s    silent mode",
    "  -nb   disable backup",
    "  -ni   disable input lag patch",
    "  -nj   disable joystick patch",
    "  -ns   disable scheduler patch",
    "  -nr   disable display reset patch",
    "  -nm   disable memory patch",
    "  -nd   disable DirectPlay Patch",
    "",
}

--| Argument parsing |----------------------------------------------------------

local inputFile
local isSilent, makeBackup = false, true
local disabledPatch = {}

for i=1, #arg do
    local arg = arg[i]

    if arg == "-h"  then
        print(titleBox)
        print(help)
        exit(1)

    elseif arg == "-s"  then isSilent   = true
    elseif arg == "-nb" then makeBackup = false
    elseif arg == "-nj" then disabledPatch[PatchType.JOY]      = true
    elseif arg == "-nm" then disabledPatch[PatchType.MEM]      = true
    elseif arg == "-nd" then disabledPatch[PatchType.DPLAY]    = true
    elseif arg == "-ns" then disabledPatch[PatchType.SCHED]    = true
    elseif arg == "-ni" then disabledPatch[PatchType.INPUTLAG] = true
    elseif arg == "-nr" then disabledPatch[PatchType.RESET]    = true

    -- Select last inputted file if multiple file is supplied
    else inputFile = arg end
end

-- Show title if not in silent mode
if not isSilent or inputFile == nil then
    print(titleBox)
end

-- Check if user disabled all patches
local isAllPatchesDisabled = true

for i=1, #PatchType do
    if disabledPatch[i] ~= true then
        isAllPatchesDisabled = false
        break
    end
end

if isAllPatchesDisabled then
    print "All patches is disabled, no operation will be performed."
    exit(1)
end

-- No file specified
if inputFile == nil then
    print "Input file is not specified."
    print ""
    print(help)
    exit(1)
end

-- Disable print and prompt if silent mode is on
if isSilent then
    print  = function() end
    prompt = function() return true end
end

--| Reading input file |--------------------------------------------------------

print("Inspecting file %s...\n", inputFile)

local file, err = io.open(inputFile, "r+b")

-- Can't open file
if file == nil then
    print("Could not open file (%s).", err)
    exit(1)
end

-- No MZ header
if file:read(2) ~= "MZ" then
    print "This is not an executable file."
    file:close()
    exit(1)
end

--| Scanning patches |----------------------------------------------------------

local patchList = require "patches"
local hasAppliedPatch, canApplyPatch = false, false

for _,patch in pairs(patchList) do
    patch.state = check_patch(file, patch.bytes)

    -- Assume patch is not found if patch is disabled
    if disabledPatch[patch.type] and patch.state == PatchState.ABLE then
        patch.state = PatchState.UNFOUND
    end

    -- There are patch that has been applied
    if patch.state == PatchState.DONE then
        hasAppliedPatch = true
    end

    -- There are patch that can be applied
    if patch.state == PatchState.ABLE then
        canApplyPatch = true
    end
end

-- No applicable patch
if not canApplyPatch and not hasAppliedPatch then
    print "This game cannot be patched."
    print "It may not be a GameMaker 7.0, 8.0, or 8.1 game."
    file:close()
    exit(1)
end

-- List applied patches
if hasAppliedPatch then
    print "Patches already applied:"
    for _,patch in pairs(patchList) do
        if patch.state == PatchState.DONE then
            print(" * %s", patch.name)
        end
    end
end
print ""

-- List applicable patches
if canApplyPatch then
    print "Patches can be applied:"
    for _,patch in pairs(patchList) do
        if patch.state == PatchState.ABLE then
            print(" * %s", patch.name)
        end
    end
else
    -- All patch has been applied
    print "No new patches can be applied."
    file:close()
    exit(1)
end
print ""

--| Applying patches |----------------------------------------------------------

-- Backup file
if makeBackup then
    print "Backup will be made before applying patches.\n"

    local backupName = inputFile .. '.bak'
    local backupFile = io.open(backupName, "rb")
    local doBackup   = backupFile == nil

    if backupFile then
        backupFile:close()

        print("Previous backup file exist on %s", backupName)

        doBackup = prompt "Do you want to overwrite backup file?"
            or not prompt "Continue applying patches without backup?"
               and exit(1)
    end

    if doBackup then
        os.execute("copy " .. inputFile .. " " .. backupName)
    end
end
print ""

-- Begin applying patch
local joystickPatched = false

for _,patch in ipairs(patchList) do
    -- Check if joystick already patched
    if patch.type == PatchType.JOY and patch.state == PatchState.DONE then
        joystickPatched = true
    end

    -- Warn if joystick is not patched
    if patch.state == PatchState.ABLE then
        if patch.type == PatchType.SCHED and not joystickPatched then
            print "Joystick patch is not applied."
            print "Scheduler patch may not work without joystick patch."
        end

        -- Apply patch
        if prompt("Apply %s?", patch.name) then
            patch_exe(file, patch.bytes)

            if patch.type == PatchType.JOY then
                joystickPatched = true
            end
        end
    end
end

file:close()
print "All done!\n"

exit(0)