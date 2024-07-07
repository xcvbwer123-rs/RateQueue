-- RateQueue 예시
local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")

local RateQueue = require(game:GetService("ReplicatedStorage"):WaitForChild("RateQueue")) ---@module module
local AwardQueue = RateQueue.new("AwardQueue", 85) -- 뱃지 서비스 메소드 요청은 분당 50 + 35 * 플레이어수이므로 최소 요청 횟수로 맞춤

local function AwardBadgesToPlayers(BadgeIds: {number})
    for _, Player in ipairs(Players:GetPlayers()) do
        for _, BadgeId in ipairs(BadgeIds) do
            AwardQueue:insert(function()
                return BadgeService:AwardBadge(Player.UserId, BadgeId)
            end):andThen(function(Success)
                if Success then
                    print(`{Player.Name} is awarded {BadgeId}!`)
                end
            end):catch(function(Error)
                warn(`Badge Award failed! : {Error}`)
            end)
        end
    end
end

AwardBadgesToPlayers({
    -- some badge ids
})

-- Waitter 예시
local TeleportService = game:GetService("TeleportService")

local RateQueue = require(game:GetService("ReplicatedStorage"):WaitForChild("RateQueue")) ---@module module
local RequestWaitter = RateQueue.Waitter()

for _, Player in ipairs(Players:GetPlayers()) do
    RequestWaitter:insert(RateQueue.Process(function()
        TeleportService:Teleport(game.PlaceId, Player)
    end))
end

RequestWaitter:executeAll():await():destroy()

print("Teleport completed!")