require "lunit"

Suite = LUnit.Initialize("Example suite", "testable.lua")
-- Each suite holds 1 or more tests.
-- After we Initialize the suite with a name, we can go ahead and (re)define functions within the tests'
-- sandboxed environment.
-- Tests are sandboxed to think that Suite.Env is _G.

Suite.Env.print = Suite.Capture("thingsPrinted")
-- We can capture values passed to a function by creating a capture function with "Suite.Capture(key)".
-- Values are passed back to the suite's capture registry, and we can access the captured values later
-- by calling Suite:GetCaptured() - or just GetCaptured within a test function.

Suite.PrepareFile()
-- Loads and sandboxes the contents of the file we're testing into Suite.Env



-- Defining a test: Tests should really have at least 1 Assert() chain to be useful.
Suite.DefineTest("mytable.fizBuz", "It should check fizbuz results", function(Env)
    local _G = Env
    mytable.fizBuz(3)
    Assert("thingsPrinted"):CapturedTimes(8):Log("Should have called print 8 times") -- should be a fail!
    Assert("thingsPrinted"):CapturedTimes(24):Log("Ok, maybe it should have called print 24 times") -- should be a success!

    local cap = GetCaptured("thingsPrinted")
    Assert(cap[#cap][1]):Equals("buz"):Log("Last number should have finished by printing 'buz'") -- should be a success!
end)



local noFailures = Suite.RunAllTests()
-- Total failures and successes are not counted per test, they're counted per assertion.
