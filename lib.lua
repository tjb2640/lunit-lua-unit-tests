LUnitLib = {
    Version = "0.0.2"
}

-- Rough string.find through a file to check for lines that might be worth covering
LUnitLib.GetCoverable = function(filename)
    local find_word = function(line)
        -- Anything containing these words
        for _, word in next, {"do", "local", "return"}, nil do
            -- frontier pattern for whole word (%a)
            local found = string.find(line, "%f[%a]" .. word .. "%f[%A]")
            if found and (found ~= line:gsub(" ", "")) then return found end
        end
    end

    local find_symbols = function(line)
        -- Any symbol within the []
        local found = string.find(line, "[%(.%-+/%*%%%)]")
        if found ~= line:gsub(" ", "") then return found end
    end

    local find_comment = function(line)
        return string.find(line, "%-%-")
    end

    local L = 0
    local maybeSignificantLines = {}
    for line in io.lines(filename) do
        L = L + 1
        local found = find_word(line) or find_symbols(line)
        if found then
            local comment = find_comment(line)
            if (not comment) or (found < comment) then
                maybeSignificantLines[L] = true
            end
        end
    end

    return maybeSignificantLines
end
LUnitLib.CompileCoverageInfo = function(Coverage)
    local touched = {}
    for L, _ in next, Coverage.Lines.Coverable, nil do
        touched[L] = false
    end

    Coverage.Lines.Covered = 0
    for L, stat in next, Coverage.Lines.History, nil do
        if touched[L] == false and Coverage.Lines.Coverable[L] then
            Coverage.Lines.Covered = Coverage.Lines.Covered + 1
            touched[L] = true
        end
    end

    return results
end
LUnitLib.GetLuaVersion = function()
    return _VERSION:sub(-3)
end
LUnitLib.KeySet = function(tbl)
    local keys = {}
    for k,_ in next, tbl, nil do
        table.insert(keys, k)
    end
    return keys
end
LUnitLib.TableCount = function(tbl)
    local i = 0
    for k,v in next, tbl, nil do
        i = i + 1
    end
    return i
end
