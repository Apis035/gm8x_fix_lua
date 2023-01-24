write, wait, exit = io.write, io.read, os.exit

local _ = print
function print(str, ...)
    _(tostring(str):format(...))
end

function prompt(msg, ...)
    local char

    while char ~= 'y' and char ~= 'n' do
        io.write((msg .. " [y/n] "):format(...))
        char = string.lower(io.read())
    end

    return char == 'y'
end