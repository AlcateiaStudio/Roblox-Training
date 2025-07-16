PlayerMatchManagerInfos = {}

local ClientScriptService = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Net = require(ClientScriptService.Client.Net)
local PlayerController = require(ClientScriptService.Client.Player.PlayerController)
local localPlayer = Players.LocalPlayer
local COIN_TAG = "Coin"
local CHECKPOINT_TAG = "Checkpoint"
local CHECKPOINT_RESPAW_TAG = "RespawnArea"

local CanInteractWithRace = false
local CoinTaggedParts = CollectionService:GetTagged(COIN_TAG) :: { Model }
local CheckpointTaggedParts = CollectionService:GetTagged(CHECKPOINT_TAG) :: { Model }
local CheckpointRespawnTaggedParts = CollectionService:GetTagged(CHECKPOINT_RESPAW_TAG) :: { BasePart }

local timeToTPMax = 1.5
local timeToTP = 0
local Teleporting = false
local CurrentCheckpointRunIndex = 0

function PlayerMatchManagerInfos:Start()
	local function CanInteract(hit: BasePart)
		if hit.Parent ~= localPlayer.Character then
			return false
		end
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

	local function OnPlayerReachedFinishLine()
		PlayerReachedFinishLine()
	end

	Net.RaceStarted.On(OnRaceStarted)
	Net.RaceFinished.On(OnRaceFinished)
	Net.PlayerReachedFinishLine.On(OnPlayerReachedFinishLine)

	CollectionService:GetInstanceAddedSignal(COIN_TAG):Connect(function(instance: Instance)
		AssignTouchedConnection(instance, CoinTaggedParts)
	end)

	CollectionService:GetInstanceAddedSignal(CHECKPOINT_TAG):Connect(function(instance: Instance)
		AssignTouchedConnection(instance, CheckpointTaggedParts)
	end)

	CollectionService:GetInstanceRemovedSignal(COIN_TAG):Connect(function(instance: Instance)
		RemoveTouchedConnection(instance, CoinTaggedParts)
	end)

	CollectionService:GetInstanceRemovedSignal(CHECKPOINT_TAG):Connect(function(instance: Instance)
		RemoveTouchedConnection(instance, CheckpointTaggedParts)
	end)

	for _, coin in ipairs(CoinTaggedParts) do
		coin.PrimaryPart.Touched:Connect(function(hit)
			if CanInteract(hit) == false then
				return
			end
			local temp = coin:GetAttribute("UID") :: number
			Net.SendCoinsOnPlayerEntered.Fire(temp)
		end)
	end

	for _, checkPoint: Model in ipairs(CheckpointTaggedParts) do
		local temp = checkPoint:GetAttribute("CheckpointID")
		local checkpointBasePart: BasePart
		if checkPoint:IsA("BasePart") then
			checkpointBasePart = checkPoint :: BasePart
			print(` {checkpointBasePart}`)

			checkpointBasePart.Touched:Connect(function(hit)
				if CanInteract(hit) == false then
					return
				end
				PlayerMatchManagerInfos:TouchedCheckpoint(temp)
			end)

			local respawnPosition = checkpointBasePart:FindFirstChild("RespawnPosition") :: BasePart

			checkpointBasePart.Transparency = 1
			respawnPosition.Transparency = 1
		end
	end

	for _, respawnZone in ipairs(CheckpointRespawnTaggedParts) do
		if respawnZone:IsA("BasePart") then
			local basePart = respawnZone
			basePart.Touched:Connect(function(hit)
				if CanInteract(hit) == false then
					return
				end
				PlayerMatchManagerInfos:RespawnPlayerOnLastCheckpoint(hit.Parent)
			end)

			basePart.Transparency = 1
		end
	end

	local function OnHeartBeat(...)
		self:_OnHeartbeat(...)
	end

	RunService.Heartbeat:Connect(OnHeartBeat)
end

function PlayerMatchManagerInfos:TouchedCheckpoint(index: number)
	if CurrentCheckpointRunIndex == index then
		return
	end

	if CurrentCheckpointRunIndex + 1 ~= index then
		return
	end

	CurrentCheckpointRunIndex = index
	Net.PlayerReacheadNewCheckpoint.Fire(CurrentCheckpointRunIndex)
end

function PlayerReachedFinishLine()
	CurrentCheckpointRunIndex = 0
end

function PlayerMatchManagerInfos:_OnHeartbeat(deltaTime)
	self:HandleTeleporting(deltaTime)
	self:RotateCoins(deltaTime)
end

function PlayerMatchManagerInfos:HandleTeleporting(deltaTime: number)
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

function PlayerMatchManagerInfos:RespawnPlayerOnLastCheckpoint(Player: Model)
	if Teleporting == true then
		return
	end

	Teleporting = true
	PlayerController:SetPlayerState(2)

	local Position: BasePart
	for _, checkPoint: BasePart in ipairs(CheckpointTaggedParts) do
		local index = checkPoint:GetAttribute("CheckpointID")

		if index ~= CurrentCheckpointRunIndex then
			continue
		end

		local respawnPosition = checkPoint:FindFirstChild("RespawnPosition") :: BasePart

		Position = respawnPosition
		break
	end

	task.spawn(function()
		while Teleporting == true do
			task.wait()
		end
		PlayerController:SetPlayerState(0)
		local newCFrame = CFrame.new(Position.CFrame.Position + Vector3.new(0, 2, 0)) * Position.CFrame.Rotation
		Player:PivotTo(newCFrame)
	end)
end

function PlayerMatchManagerInfos:RotateCoins(deltaTime: number)
	local rotationY = math.rad(180) * deltaTime

	for _, coin in pairs(CoinTaggedParts) do
		local coinModel = coin:FindFirstChild("CoinModel") :: BasePart

		coinModel.CFrame *= CFrame.Angles(0, rotationY, 0)
	end
end

PlayerMatchManagerInfos:Start()

return PlayerMatchManagerInfos
