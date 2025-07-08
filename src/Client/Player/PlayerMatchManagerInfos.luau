PlayerMatchManagerInfos = {}

local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ReplicatedStorage")
local Net = require(ServerScriptService.Client.Net)
local COIN_TAG = "Coin"

local taggedParts = CollectionService:GetTagged(COIN_TAG) :: { Model }

function PlayerMatchManagerInfos:Start()
	for _, coin in ipairs(taggedParts) do
		coin.PrimaryPart.Touched:Connect(function(hit)
			local temp = coin:GetAttribute("UID") :: number
			Net.SendCoinsOnPlayerEntered.Fire(temp)
		end)
	end
end

PlayerMatchManagerInfos:Start()

return PlayerMatchManagerInfos
