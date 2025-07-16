MatchManagerRunController = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ServerNet = require(ServerScriptService.Server.Net)
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local maxIndex = -1

local CHECKPOINT_TAG = "Checkpoint"

local CheckpointTaggedParts = CollectionService:GetTagged(CHECKPOINT_TAG) :: { Model }
local CheckpointPositions = {}

local PlayerTable = {}

local Net = require(ServerScriptService.Server.Net)

function MatchManagerRunController:Start()
	local function OnPlayerReachedCheckpoint(...)
		self:PlayerReachedCheckpoint(...)
	end

	local function OnHeartbeat(...)
		self:_OnHeartbeat(...)
	end

	maxIndex = -1
	for _, checkpointModel in ipairs(CheckpointTaggedParts) do
		local id = checkpointModel:GetAttribute("CheckpointID")
		if id ~= nil then
			local basePart = checkpointModel:FindFirstChildWhichIsA("BasePart")
			if basePart then
				CheckpointPositions[id] = basePart.Position
			end
			if id > maxIndex then
				maxIndex = id
			end
		end
	end

	ServerNet.PlayerReacheadNewCheckpoint.On(OnPlayerReachedCheckpoint)
	RunService.Heartbeat:Connect(OnHeartbeat)
end

function MatchManagerRunController:_OnHeartbeat(deltaTime)
	self:OrderPlayer()
end

function MatchManagerRunController:OrderPlayer()
	table.sort(PlayerTable, function(a, b)
		if a.lap ~= b.lap then
			return a.lap > b.lap
		end

		if a.checkpoint ~= b.checkpoint then
			return a.checkpoint > b.checkpoint
		end

		local distA = self:GetDistanceToNextCheckpoint(a.player, a.checkpoint)
		local distB = self:GetDistanceToNextCheckpoint(b.player, b.checkpoint)

		return distA < distB
	end)
	for _, playerTable in ipairs(PlayerTable) do
		Net.PlayerPlacementChanged.Fire(playerTable.player, _)
	end
end

function MatchManagerRunController:GetDistanceToNextCheckpoint(player: Player, currentCheckpointID: number): number
	local character = player.Character
	if not character then
		return math.huge
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return math.huge
	end

	local nextCheckpointID = currentCheckpointID + 1
	if nextCheckpointID >= maxIndex then
		nextCheckpointID = 1
	end
	local nextCheckpointPos = CheckpointPositions[nextCheckpointID]

	if not nextCheckpointPos then
		return math.huge -- fallback: não existe próximo checkpoint
	end

	return (root.Position - nextCheckpointPos).Magnitude
end

function MatchManagerRunController:PlayerReachedCheckpoint(_player: Player, index: number)
	for _, playerTable in pairs(PlayerTable) do
		if playerTable.player == _player then
			playerTable.checkpoint = index
			print(`Player :{playerTable.player} Checkpoint :{playerTable.checkpoint}, Lap :{playerTable.lap}`)
			break
		end
	end
end

function MatchManagerRunController:PlayerReachedFinishLine(player: Player)
	ServerNet.PlayerReachedFinishLine.Fire(player)
end

function MatchManagerRunController:OnPlayerEnter(_player: Player)
	local playerTable = { player = _player, checkpoint = 0, lap = 0, finished = false }
	table.insert(PlayerTable, playerTable)
end

function MatchManagerRunController:GetPlayerTable(_player: Player)
	for _, playerTable in pairs(PlayerTable) do
		if playerTable.player == _player then
			return playerTable
		end
	end
	return
end

function MatchManagerRunController:GetAllPlayersTable()
	return PlayerTable
end

function MatchManagerRunController:CleanAllPlayers()
	PlayerTable = {}
end

return MatchManagerRunController
