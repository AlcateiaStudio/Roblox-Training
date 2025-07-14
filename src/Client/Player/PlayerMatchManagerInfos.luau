PlayerMatchManagerInfos = {}
local ClientScriptService = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Net = require(ClientScriptService.Client.Net)
local PlayerController = require(ClientScriptService.Client.Player.PlayerController)
local COIN_TAG = "Coin"
local CHECKPOINT_TAG = "Checkpoint"

local CanInteractWithRace = false
local CointaggedParts = CollectionService:GetTagged(COIN_TAG) :: { Model }
local CheckpointtaggedParts = CollectionService:GetTagged(CHECKPOINT_TAG) :: { Model }

local timeToTPMax = 1.5
local timeToTP = 0
local Teleporting = false
local CurrentCheckpointRunIndex = 0

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

	local function OnPlayerReachedFinishLine()
		PlayerReachedFinishLine()
	end

	Net.RaceStarted.On(OnRaceStarted)
	Net.RaceFinished.On(OnRaceFinished)
	Net.PlayerReachedFinishLine.On(OnPlayerReachedFinishLine)

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
			local temp = checkPoint:GetAttribute("CheckpointID")
			local checkpointBasePart: BasePart
			if checkPoint:IsA("BasePart") then
				checkpointBasePart = checkPoint :: BasePart
				print(` {checkpointBasePart}`)

				checkpointBasePart.Touched:Connect(function(hit)
					if CanInteract() == false then
						return
					end
					PlayerMatchManagerInfos:TouchedCheckpoint(temp)
				end)
			end

			for ___, areaDetector in ipairs(checkPoint:GetChildren()) do
				if areaDetector:IsA("BasePart") then
					local basePart = areaDetector :: BasePart
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

function PlayerMatchManagerInfos:TeleportPlayer(Player: Model, Position: Vector3)
	Teleporting = true
	PlayerController:SetPlayerState(2)

	local Position: Vector3
	for _, checkPointArea: Model in ipairs(CheckpointtaggedParts) do
		for __, checkPoint: Instance in ipairs(checkPointArea:GetChildren()) do
			local index = checkPoint:GetAttribute("CheckpointID")

			if index ~= CurrentCheckpointRunIndex then
				continue
			end
			local checkpointPad = checkPoint :: BasePart
			Position = checkpointPad.Position
			break
		end
	end

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
