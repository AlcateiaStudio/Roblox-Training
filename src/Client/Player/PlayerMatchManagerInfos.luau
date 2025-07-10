PlayerMatchManagerInfos = {}
local ClientScriptService = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Net = require(ClientScriptService.Client.Net)
local COIN_TAG = "Coin"
local CHECKPOINT_TAG = "Checkpoint"
local CanInteractWithRace = false
local CointaggedParts = CollectionService:GetTagged(COIN_TAG) :: { Model }
local CheckpointtaggedParts = CollectionService:GetTagged(CHECKPOINT_TAG) :: { Model }

local PlayerController = require(ClientScriptService.Client.Player.PlayerController)

local timeToTPMax = 1.5
local timeToTP = 0
local Teleporting = false

function PlayerMatchManagerInfos:Start()
	local function CanInteract()
		return CanInteractWithRace
	end

	local function AssignTouchedConnection(instance: Instance, ListTabble: { Model })
		table.insert(ListTabble, instance :: Model)
	end

	local function RemoveTouchedConnection(instance: Instance, ListTabble: { Model })
		local model = instance :: Model
		for index, coin in ipairs(ListTabble) do
			if coin == model then
				table.remove(ListTabble, index)
			end
		end
	end

	Net.RaceStarted.On(OnRaceStarted)
	Net.RaceFinished.On(OnRaceFinished)

	CollectionService:GetInstanceAddedSignal(COIN_TAG):Connect(function(instance: Instance)
		AssignTouchedConnection(instance, CointaggedParts)
	end)

	CollectionService:GetInstanceAddedSignal(CHECKPOINT_TAG):Connect(function(instance: Instance)
		AssignTouchedConnection(instance, CheckpointtaggedParts)
	end)

	CollectionService:GetInstanceRemovedSignal(COIN_TAG):Connect(function(instance: Instance)
		RemoveTouchedConnection(instance, CointaggedParts)
	end)

	CollectionService:GetInstanceRemovedSignal(CHECKPOINT_TAG):Connect(function(instance: Instance)
		RemoveTouchedConnection(instance, CheckpointtaggedParts)
	end)

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

	RunService.Heartbeat:Connect(_OnHeartbeat)
end

function _OnHeartbeat(deltaTime)
	HandleTeleporting(deltaTime)
end

function HandleTeleporting(deltaTime: number)
	if Teleporting == false then
		return
	end

	timeToTP += deltaTime
	if timeToTP < timeToTPMax then
		return
	end
	timeToTP = 0
	Teleporting = false
end

function OnRaceStarted()
	CanInteractWithRace = true
end

function OnRaceFinished()
	CanInteractWithRace = false
end

function PlayerMatchManagerInfos:TeleportPlayer(Player: Model, Position: Vector3)
	Teleporting = true
	PlayerController:SetPlayerState(2)

	task.spawn(function()
		while Teleporting == true do
			task.wait()
		end
		PlayerController:SetPlayerState(0)
		local newCFrame = CFrame.new(Position + Vector3.new(0, 2, 0))
		Player:PivotTo(newCFrame)
	end)
end

PlayerMatchManagerInfos:Start()

return PlayerMatchManagerInfos
