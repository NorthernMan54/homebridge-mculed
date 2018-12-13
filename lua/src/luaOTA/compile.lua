--SAFETRIM

-- Compile code and remove original .lua files.
-- This only happens the first time afer the .lua files are uploaded.
-- Skip init.lua!

return function(filename)
    local function compileAndRemoveIfNeeded(f)
        if file.exists(f) then
            print('Compiling:', f)
            collectgarbage()
            tmr.wdclr()
            print("Heap Available: C " .. node.heap())
            node.compile(f)
            file.remove(f)
            print("done")
            collectgarbage()
        end
    end

    if filename then
        compileAndRemoveIfNeeded(filename)
    else
        local allFiles = file.list()
        for f,s in pairs(allFiles) do
            if f~="init.lua" and f~="test.lua" and #f >= 4 and string.sub(f, -4, -1) == ".lua" then
                compileAndRemoveIfNeeded(f)
            end
        end
        allFiles = nil
    end

    compileAndRemoveIfNeeded = nil
    collectgarbage()
    print("Compile completed, rebooting")
    tmr.create():alarm(2000, tmr.ALARM_SINGLE, function()
      node.restart() -- reboot just schedules a restart
    end)
end
