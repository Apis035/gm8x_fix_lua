local function char(byte)
    return type(byte) == "number" and string.char(byte) or byte
end

local function enum(list)
    local enum = {}
    for i, entry in ipairs(list) do
        enum[entry] = i
        enum[i]     = entry
    end
    return enum
end

PatchType = enum {
    "UPX",
    "JOY",
    "MEM",
    "DPLAY",
    "SCHED",
    "INPUTLAG",
    "RESET"
}

PatchState = enum {
    "UNFOUND",
    "ABLE",
    "DONE"
}

function PatchByte(list) -- struct
    local struct = {}
    for i, member in ipairs(list) do
        struct[i] = {}
        struct[i].pos      =      member[1]  -- int
        struct[i].origByte = char(member[2]) -- uint8_t
        struct[i].newByte  = char(member[3]) -- uint8_t
    end
    return struct
end

function Patch(list) -- struct
    local struct = {}
    for i=1, #list do
        struct[i] = {}
        struct[i].bytes = list[i][1] -- PatchByte*
        struct[i].name  = list[i][2] -- char*
        struct[i].type  = list[i][3] -- PatchType
        struct[i].state = list[i][4] -- PatchState
    end
    return struct
end