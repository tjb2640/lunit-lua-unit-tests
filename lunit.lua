LUnit = {
    AssertionInfo = {
        Success = {},
        Fail = {},
    },
    Version = "0.0.1",
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

-- Populates the tests' environment with some basic stuff, mostly passing through libraries from _G.
LUnit._populateEnvironment = function(G)
    G.print = function(s) print("  [Test environment] ", s) end
    G.math = math
    G.table = table
    G.string = string
    G.pairs = pairs
    G.next = next
end

-- Returns: table holding testing functions and a simple sandbox for mocking
LUnit.Initialize = function(suiteName, fileName)
    local ENV = {}
    LUnit._populateEnvironment(ENV)
    local Suite = {
        gptr = _G,
        Env = ENV,
        FileName = fileName,
        Mocks = {},
        Name = suiteName,
        _captures = {},
        _tests = {}
    }

    -- captures - Capture returns a generated function that stores all args passed to it, along w/ the number of times
    -- the function was called...
    Suite.Capture = function(key)
        -- return a mock function
        local x = function(...)
            Suite._captures[key] = Suite._captures[key] or {}
            table.insert(Suite._captures[key], {...})
        end
        return x
    end
    -- retrieve captured values - will always return a table of the captured values
    Suite.GetCaptured = function(key, idx)
        local result = Suite._captures[key] or {}
        if idx then
            return result[idx]
        end
        return result
    end
    -- clear captures, pass nothing to clear all, or pass a value for a specific key
    Suite.ClearCaptured = function(key)
        if key == nil then
            Suite._captures = {}
        else
            Suite._captures[key] = nil
        end
    end
    Suite.DefineTest = function(name, description, funcPtr)
        -- do magic tricks
        setfenv(funcPtr, Suite.Env)
        table.insert(Suite._tests, {
            name = name,
            description = description,
            funcPtr = funcPtr,
        })
    end
    Suite.PrepareFile = function()
        Suite.Env._G = Suite.Env
        Suite.Env.debug = {}
        local loadFunction, err = loadfile(Suite.FileName)
        assert(err == nil, string.format("ERROR loading file: %s", err))
        setfenv(loadFunction, Suite.Env)
        loadFunction()
    end
    Suite.RunAllTests = function()
        for i = 1, #Suite._tests do
            local test = Suite._tests[i]
            print(string.format("%s: %s", test.name, test.description))
            test.funcPtr()
        end
        -- print stats
        LUnitLib.OrganizeTestStats(LUnit.AssertionInfo):Print(Suite.Name)
    end

    -- Allow for assertions inside the tests
    Suite.Env.Assert = Assertions.Assert
    Suite.Env.GetCaptured = Suite.GetCaptured
    LUnit.Suite = Suite
    return Suite
end
