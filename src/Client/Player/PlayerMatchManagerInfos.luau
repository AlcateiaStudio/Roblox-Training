PlayerMatchManagerInfos = {}

local ClientScriptService = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Net = require(ClientScriptService.Client.Net)
local COIN_TAG = "Coin"
local CanCollectCoin = false
local taggedParts = CollectionService:GetTagged(COIN_TAG) :: { Model }

function PlayerMatchManagerInfos:Start()
	Net.RaceStarted.On(EnableCollectCoins)
	Net.RaceFinished.On(DisableCollectCoins)

	for _, coin in ipairs(taggedParts) do
		coin.PrimaryPart.Touched:Connect(function(hit)
			if CanCollectCoin == false then
				return
			end
			local temp = coin:GetAttribute("UID") :: number
			Net.SendCoinsOnPlayerEntered.Fire(temp)
		end)
	end
end

function EnableCollectCoins()
	CanCollectCoin = true
end

function DisableCollectCoins()
	CanCollectCoin = false
end

PlayerMatchManagerInfos:Start()

return PlayerMatchManagerInfos
