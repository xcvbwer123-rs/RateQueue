---@module module
local RateQueue = require(game:GetService("ReplicatedStorage"):WaitForChild("RateQueue"))

-- 초당 1번씩만 실행되는 큐
local TestQueue = RateQueue.new("TestQueue", nil, 1)
local progress = 0

for index = 1, 10 do
    TestQueue:insert(function()
        task.wait(math.random()) -- Yield 하는것도 넣을수 있음
        print(`Task #{index} Completed.`)
    end):andThen(function()
        progress += 1
        print(`Progress : {progress} / 10`)
    end)
end

TestQueue:insertFront(function()
    print("Front inserted task!")
end)

local process = TestQueue:insert(function()
    print("this may ignored!")
end)

TestQueue:insert(function()
    print("Last inserted task!")
end):await():andThen(function()
    print("all tasks completed!!")
end)

if TestQueue:remove(process) then
    print("remove completed!")
else
    print("remove failed!")
end