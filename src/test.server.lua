---@module module
local RateQueue = require(game:GetService("ReplicatedStorage"):WaitForChild("RateQueue"))

local testTask = RateQueue.new(function(a, b, c)
    print("run begin")
    print(a, b, c)
    return "asdf"
end, "a", "b", "c")