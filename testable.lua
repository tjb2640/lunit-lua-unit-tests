-- Dummy file that is tested by example.lua
mytable = {}
mytable = {
    fizBuz = function(n)
        local times = 0
        for i = 1, n * 15 do
            if i % 3 == 0 then
                print("fiz")
            end
            if i % 5 == 0 then
                print("buz") 
            end
        end
    end,
    noCoverage = function(s) -- uncovered (7/8)
        local x = 10 -- uncovered x2 (7/9)
        print(x) -- uncovered x3 (7/10)
    end
} -- this is the end of my file...
