LUnit = {
    ResetAssertionInfo = function()
        LUnit.AssertionInfo = {
            Success = {},
            Fail = {},
        }
    end,
    Version = "0.0.2",
}

require "lib"
require "assertions"

-- Lua 5.2+ uses _ENV instead of get/setfenv, but we can just alias the old functions to work with _ENV
local setfenv = setfenv
local getfenv = getfenv
if setfenv == nil then
    print(string.format("Lua version %s is using _ENV instead of set/getfenv, will alias them instead", LUnitLib.GetLuaVersion()))
    
    local getupvalue = debug.getupvalue
    local upvaluejoin = debug.upvaluejoin

    setfenv = function(funcPtr, env)
        local level = 1
        local name = getupvalue(funcPtr, level)
        while (name ~= nil) and (name ~= "_ENV") do
            level = level + 1
            name = getupvalue(funcPtr, level)
        end
        if name == "_ENV" then
            upvaluejoin(funcPtr, level, function() return env end, 1)
        end
        return funcPtr
    end

    getfenv = function(funcPtr)
        local level = 1
        local name, env = getupvalue(funcPtr, level)
        while (name ~= nil) and (name ~= "_ENV") do
            level = level + 1
            name, env = getupvalue(funcPtr, level)
        end
        return name == "_ENV" and env or nil
    end
end

-- Returns a populated environment with some basic stuff, mostly passing through libraries from _G.
LUnit.NewEnvironment = function()
    local G = {
        print = function(s) print("  [Test environment] ", s) end,
        math = math,
        table = table,
        string = string,
        pairs = pairs,
        ipairs = ipairs,
        next = next,
    } 
    return G
end

-- Returns: table holding testing functions and a simple sandbox for mocking
LUnit.Initialize = function(suiteName, fileName)
    local Suite = {
        CaptureData = {},
        Coverage = {
            Lines = {
                Areas = {},
                Coverable = {},
                Covered = {},
                History = {},
            },
        },
        Env = LUnit.NewEnvironment(),
        FileName = fileName,
        Name = suiteName,
        Tests = {}
    }

    -- Clear assertion info from other suites, if multiple are initialized in one execution.
    LUnit.ResetAssertionInfo()

    -- Immediately analyze the file for interesting lines that might be worth coverage-checking
    -- This is a rough test based on syntax but honestly results in a coverage score close to the actual
    -- coverage w/the estimated figure, and isn't too expensive
    Suite.Coverage.Lines.Coverable = LUnitLib.GetCoverable(fileName)

    -- captures - Capture returns a generated function that stores all args passed to it, along w/ the number of times
    -- the function was called...
    Suite.Capture = function(key)
        -- return a mock function
        local x = function(...)
            Suite.CaptureData[key] = Suite.CaptureData[key] or {}
            table.insert(Suite.CaptureData[key], {...})
        end
        return x
    end
    -- retrieve captured values - will always return a table of the captured values
    Suite.GetCaptured = function(key, idx)
        local result = Suite.CaptureData[key] or {}
        if idx then
            return result[idx]
        end
        return result
    end
    -- clear captures, pass nothing to clear all, or pass a value for a specific key
    Suite.ClearCaptured = function(key)
        if key == nil then
            Suite.CaptureData = {}
        else
            Suite.CaptureData[key] = nil
        end
    end
    Suite.DefineTest = function(name, description, funcPtr)
        -- Execute tested file in sandbox only once
        if not Suite.prepared then
            Suite.Env.debug = {}

            local loadFunction, err = loadfile(Suite.FileName)
            assert(err == nil, string.format("ERROR loading file: %s", err))
            setfenv(loadFunction, Suite.Env)
            loadFunction()
            Suite.prepared = true
        end
        
        -- do magic tricks
        setfenv(funcPtr, Suite.Env)
        table.insert(Suite.Tests, {
            name = name,
            description = description,
            funcPtr = funcPtr,
        })
    end
    Suite.RunAllTests = function()
        -- hook active lines for line coverage
        debug.sethook(function(event, line)
            local dinfo = debug.getinfo(2)
            if dinfo.short_src == Suite.FileName then
                -- create coverage area for given function name, start and end lines if it doesn't exist already
                Suite.Coverage.Lines.Areas[dinfo.name] = Suite.Coverage.Lines.Areas[dinfo.name] or {
                    start = dinfo.linedefined,
                    finish = dinfo.lastlinedefined
                }
                -- mark some lines as covered, including start/end lines for the function we're in
                Suite.Coverage.Lines.History[dinfo.linedefined] = dinfo.name
                Suite.Coverage.Lines.History[dinfo.lastlinedefined] = (Suite.Coverage.Lines.History[dinfo.lastlinedefined] or 0) + 1
                Suite.Coverage.Lines.History[line] = (Suite.Coverage.Lines.History[line] or 0) + 1
            end
        end, "Ll")

        -- run through each test
        for i = 1, #Suite.Tests do
            local test = Suite.Tests[i]
            print(string.format("%s: %s", test.name, test.description))
            test.funcPtr()
        end

        -- reset debug hook
        debug.sethook()

        -- put together how many of the coverable lines were actually covered
        LUnitLib.CompileCoverageInfo(Suite.Coverage)

        -- print stats
        local passedAsserts = LUnitLib.TableCount(LUnit.AssertionInfo.Success)
        local failedAsserts = LUnitLib.TableCount(LUnit.AssertionInfo.Fail)
        local passRate = 100.0 * (passedAsserts) / (passedAsserts + failedAsserts)

        print(string.rep("=", 40))
        print(string.format("%s (%s) - Results:", (Suite.Name or "Unnamed suite"), Suite.FileName))
        print(string.format("  Passing assertions:  %d", passedAsserts))
        print(string.format("  Failing assertions:  %d", failedAsserts))
        print(string.format("  Test pass rate: %0.1f%%", passRate))

        local coveredLines = Suite.Coverage.Lines.Covered
        local coverableLines = LUnitLib.TableCount(Suite.Coverage.Lines.Coverable)
        print(string.format("  Estimated line coverage: %d/%d (%0.1f%%)", coveredLines, coverableLines,
            (100.0 * coveredLines / coverableLines)))
    end

    -- Allow for assertions inside the tests
    Suite.Env.Assert = Assertions.Assert
    Suite.Env.GetCaptured = Suite.GetCaptured
    LUnit.Suite = Suite
    return Suite
end
