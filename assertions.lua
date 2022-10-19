--[[
    Assertions library:
    Meant to be used within tests; create a table that acts as an assertion stub with
        Assert(someValue)
    The basic call structure looks like Assert(something):ConditionCheck():Log()

    Within the test sandbox, Assert is a global and maps to _G.Assertions.Assert:
        Assert(4):IsNil():Log("4 should be nil") -- fails
        Assert(2):DoesNotEqual(3):Log("Obvious") -- succeeds

    Each assertion must close out with :Log() with a brief explanation
    to count the test towards the final success/fail count
]]

local _G = _G

local nilstr = function(v)
    if v == nil then
        return "nil"
    end
    return v
end

Assertions = {
    Version = "0.0.2"
}

Assertions._base_assertion = {
    -- Closers
    value = {},
    actual = {},
    expected = {},
    result = {},
    Log = function(self, explanation)
        local success = self.result == true
        -- Report back to LUnit
        if LUnit then
            local slot = success and LUnit.AssertionInfo.Success or LUnit.AssertionInfo.Fail
            slot[explanation] = success
        end
        -- Report in console
        _G.print(_G.string.format("%s: %s", success and "✅ PASS" or "❌ FAIL", explanation))
        if not success then
            _G.print(_G.string.format("\tExpected: %s, got: %s", self.expected, self.actual))
        end
        return success
    end,
    Equals = function(self, n)
        self.actual = nilstr(self.value)
        self.expected = n
        self.result = self.value == n
        return self
    end,
    DoesNotEqual = function(self, n)
        self.actual = nilstr(self.value)
        self.expected = _G.string.format("not %s", n)
        self.result = self.value ~= n
        return self
    end,
    IsNil = function(self)
        self.actual = nilstr(self.value)
        self.expected = "nil"
        self.result = self.value == nil
        return self
    end,
    IsDefined = function(self)
        self.actual = nilstr(self.value)
        self.expected = "not nil"
        self.result = self.value ~= nil
        return self
    end,
    IsType = function(self, typeName)
        self.actual = _G.type(self.value)
        self.expected = _G.string.format("type = \"%s\"", typeName)
        self.result = _G.type(self.value) == typeName
        return self
    end,
    Captured = function(self)
        self.expected = _G.string.format("captured at least once")
        if LUnit then
            self.actual = #(LUnit.Suite.GetCaptured(self.value) or {})
            self.result = self.actual > 0
        else
            self.result = false
        end
        return self
    end,
    CapturedTimes = function(self, x)
        self.expected = _G.string.format("captured exactly %s times", x)
        if LUnit then
            self.actual = #(LUnit.Suite.GetCaptured(self.value) or {})
            self.result = self.actual == x
        else
            self.result = false
        end
        return self
    end,
}

Assertions.Assert = function(val)
    local stub = {}
    _G.setmetatable(stub, { __index = Assertions._base_assertion })
    stub.value = val
    return stub
end