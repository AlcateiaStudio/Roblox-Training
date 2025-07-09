PlayerMatchManagerInfos = {}
local ClientScriptService = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Net = require(ClientScriptService.Client.Net)
local COIN_TAG = "Coin"
local CHECKPOINT_TAG = "Checkpoint"
local CanInteractWithRace = false
local CointaggedParts = CollectionService:GetTagged(COIN_TAG) :: { Model }
local CheckpointtaggedParts = CollectionService:GetTagged(CHECKPOINT_TAG) :: { Model }

function PlayerMatchManagerInfos:Start()
	local function CanInteract()
		return CanInteractWithRace
	end

	Net.RaceStarted.On(OnRaceStarted)
	Net.RaceFinished.On(OnRaceFinished)

	for _, coin in ipairs(CointaggedParts) do
		coin.PrimaryPart.Touched:Connect(function(hit)
			if CanInteract() == false then
				return
			end
			local temp = coin:GetAttribute("UID") :: number
			Net.SendCoinsOnPlayerEntered.Fire(temp)
		end)
	end

	for _, checkPointArea: Model in ipairs(CheckpointtaggedParts) do
		for __, checkPoint: Instance in ipairs(checkPointArea:GetChildren()) do
			for ___, areaDetector in ipairs(checkPoint:GetChildren()) do
				local basePart = areaDetector :: BasePart
				local checkpointBasePart = checkPoint :: BasePart
				basePart.Touched:Connect(function(hit)
					if CanInteract() == false then
						return
					end
					PlayerMatchManagerInfos:TeleportPlayer(hit.Parent, checkpointBasePart.Position)
				end)
			end
		end
	end
end

function OnRaceStarted()
	CanInteractWithRace = true
end

function OnRaceFinished()
	CanInteractWithRace = false
end

function PlayerMatchManagerInfos:TeleportPlayer(Player: Model, Position: Vector3)
	local newCFrame = CFrame.new(Position + Vector3.new(0, 2, 0))
	Player:PivotTo(newCFrame)
end

PlayerMatchManagerInfos:Start()

return PlayerMatchManagerInfos
