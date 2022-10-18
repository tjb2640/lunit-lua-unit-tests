LUnitLib = {
    Version = "0.0.1"
}
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
LUnitLib.OrganizeTestStats = function(info)
    local numSuccess = LUnitLib.TableCount(info.Success)
    local numFail = LUnitLib.TableCount(info.Fail)
    return {
        successCount = numSuccess,
        successRate = 100.0 * (numSuccess) / (numSuccess + numFail),
        failCount = numFail,
        failed = LUnitLib.KeySet(info.Fail),
        Print = function(self, suiteName)
            print(string.rep("=", 40))
            print(string.format("%s - Results:", (suiteName or "Unnamed suite")))
            print(string.format("  Successes: %d", self.successCount))
            print(string.format("  Failures: %d", self.failCount))
            print(string.format("  Rate of success: %0.1f%%", self.successRate))
        end
    }
end
