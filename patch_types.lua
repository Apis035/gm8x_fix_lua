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

local function struct(member, filter)
    local filter = filter or {}
    return function (list)
        local struct = {}
        for i=1, #member do
            for j=1, #list do
                struct[j] = struct[j] or {}
                struct[j][member[i]] =
                        filter[i] ~= nil
                    and filter[i](list[j][i])
                     or list[j][i]
            end
        end
        return struct
    end
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

PatchByte = struct (
    { "pos", "origByte", "newByte" },
    { nil, char, char }
)

Patch = struct {
    "bytes", "name", "type", "state"
}