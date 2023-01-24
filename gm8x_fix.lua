--[[ Requires ]]--

require "patch_types"
require "patches"
require "util"

--[[ Patch list ]]--

PatchList = Patch {
    { mempatch,             "Memory patch",                  PatchType.MEM },

    { joypatch_70,          "GM7.0 joystick patch",          PatchType.JOY },
    { schedpatch_70,        "GM7.0 scheduler patch",         PatchType.SCHED },
    { inputlagpatch_70,     "GM7.0 input lag patch",         PatchType.INPUTLAG },
    { dplaypatch_70,        "GM7.0 DirectPlay patch",        PatchType.DPLAY },

    { joypatch_80,          "GM8.0 joystick patch",          PatchType.JOY },
    { schedpatch_80,        "GM8.0 scheduler patch",         PatchType.SCHED },
    { inputlagpatch_80,     "GM8.0 input lag patch",         PatchType.INPUTLAG },
    { dplaypatch_80,        "GM8.0 DirectPlay patch",        PatchType.DPLAY },

    { joypatch_81_65,       "GM8.1.65 joystick patch",       PatchType.JOY },
    { schedpatch_81_65,     "GM8.1.65 scheduler patch",      PatchType.SCHED },
    { inputlagpatch_81_65,  "GM8.1.65 input lag patch",      PatchType.INPUTLAG },
    { dplaypatch_81_65,     "GM8.1.65 DirectPlay patch",     PatchType.DPLAY },

    { joypatch_81_71,       "GM8.1.71 joystick patch",       PatchType.JOY },
    { schedpatch_81_71,     "GM8.1.71 scheduler patch",      PatchType.SCHED },
    { inputlagpatch_81_71,  "GM8.1.71 input lag patch",      PatchType.INPUTLAG },
    { dplaypatch_81_71,     "GM8.1.71 DirectPlay patch",     PatchType.DPLAY },

    { joypatch_81_91,       "GM8.1.91 joystick patch",       PatchType.JOY },
    { schedpatch_81_91,     "GM8.1.91 scheduler patch",      PatchType.SCHED },
    { inputlagpatch_81_91,  "GM8.1.91 input lag patch",      PatchType.INPUTLAG },
    { dplaypatch_81_91,     "GM8.1.91 DirectPlay patch",     PatchType.DPLAY },

    { joypatch_81_135,      "GM8.1.135 joystick patch",      PatchType.JOY },
    { schedpatch_81_135,    "GM8.1.135 scheduler patch",     PatchType.SCHED },
    { inputlagpatch_81_135, "GM8.1.135 input lag patch",     PatchType.INPUTLAG },
    { dplaypatch_81_135,    "GM8.1.135 DirectPlay patch",    PatchType.DPLAY },

    { joypatch_81_140,      "GM8.1.140 joystick patch",      PatchType.JOY },
    { schedpatch_81_140,    "GM8.1.140 scheduler patch",     PatchType.SCHED },
    { inputlagpatch_81_140, "GM8.1.140 input lag patch",     PatchType.INPUTLAG },
    { dplaypatch_81_140,    "GM8.1.140 DirectPlay patch",    PatchType.DPLAY },

    { joypatch_81_141,      "GM8.1.141 joystick patch",      PatchType.JOY },
    { schedpatch_81_141,    "GM8.1.141 scheduler patch",     PatchType.SCHED },
    { inputlagpatch_81_141, "GM8.1.141 input lag patch",     PatchType.INPUTLAG },
    { resetpatch_81_141,    "GM8.1.141 display reset patch", PatchType.RESET },
    { dplaypatch_81_141,    "GM8.1.141 DirectPlay patch",    PatchType.DPLAY }
}

--[[ Split functions ]]--

function can_patch(file, patches)
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

function patch_exe(file, patches)
    for _,patch in ipairs(patches) do
        file:seek("set", patch.pos)
        file:write(patch.newByte)
    end
end

--[[ Main program ]]--

local filename, showHelp, silent, makeBackup =
      nil,      false,    false,  true

local patchDisabled = {}

-- Parse arguments
for i=1, #arg do
    local arg = arg[i]

        if arg == "-h"  then showHelp   = true break
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
if not showHelp and filename == nil then
    print "No file is specified."
    showHelp = true
end

if showHelp then
    print("Usage: %s file [options]", arg[0])
    print "       or drag the Game Maker game file into the patcher."
    print ""
    print "  -h 	show this help"
    print "  -nb	disable backup"
    print "  -ni	disable input lag patch"
    print "  -nj	disable joystick patch"
    print "  -ns	disable scheduler patch"
    print "  -nr	disable display reset patch"
    print "  -nm	disable memory patch"
    print "  -nd	disable DirectPlay patch"
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
if file:read(1) ~= 'M' or file:read(1) ~= 'Z' then
    print "This is not an executable file."
    exit()
end

local hasAppliedPatch, canApplyPatch = false, false

for _,patch in pairs(PatchList) do
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
    for _,patch in pairs(PatchList) do
        if patch.state == PatchState.DONE then
            print(" * %s", patch.name)
        end
    end
end

-- Patch can be applied
if canApplyPatch then
    print "Patches that can be applied:"
    for _,patch in pairs(PatchList) do
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
    local overwriteBackup = false
    local doBackup        = false

    local checkFile = io.open(backupFilename, "rb")
    local prevBackupExist = checkFile ~= nil

    if prevBackupExist then
        checkFile:close()
        print("Previous backup file exist on %s", backupFilename)
        overwriteBackup = prompt "Do you want to overwrite backup file?"
    end

    if prevBackupExist then
        if overwriteBackup then
            doBackup = true
        elseif not prompt "Continue applying patches without backup?" then
            exit()
        end
    else
        doBackup = true
    end

    if doBackup then
        os.execute("copy " .. filename .. " " .. backupFilename)
    end
end

-- Apply patches
file = io.open(filename, "r+b")
local joyPatched = false

for _,patch in ipairs(PatchList) do
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