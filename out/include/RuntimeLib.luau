local RuntimeLib = {}

function RuntimeLib.import(scriptInstance, ...)
    local segments = {...}
    local current = scriptInstance
    
    for _, segment in ipairs(segments) do
        if segment == ".." or segment == "Parent" then
            current = current.Parent
        elseif segment == "." then
            -- Stay
        else
            current = current:WaitForChild(segment)
        end
    end
    
    return require(current)
end

return RuntimeLib
