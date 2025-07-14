local MatchManagerModule = {}
MatchManagerModule.ManagerStatus = {
	WaitingForTp = 0,
	WaitingToStarRace = 1,
	WaitingForRaceFinish = 2,
	WaitingForPodium = 3,
}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local AreaDetectorComponent = require(ServerScriptService.Server.Components.ServerAreaDetector)
local ExplorerUtils = require(ReplicatedStorage.Shared.Utils.ExplorerUtils)
local GameSettings = require(ReplicatedStorage.Shared.Data.GameSettings)
local MatchManagerRunController = require(ServerScriptService.Server.Services.MatchManagerRunController)
local Net = require(ServerScriptService.Server.Net)
local Signal = require(ReplicatedStorage.Packages.Signal)

local Max_Player_To_Run = 4
local Time_To_Stay_On_Podium = 5
local Time_Max_To_Await_To_TP = 3
local MinimunPlayersToStart = 1
local MaxLaps = 3

local listaDePlayers = {}
local listaDeCharacters = {}
local TransformsToStarRace = {}
local TransformsToPodium = {}
local maxIndex = -1

local CurrentTimeToTP = 0
local CurrentTimeToStarRace = 0
local currentTimeOnPodium = 0
local QuantityPlayersCrossedFinishLine = 0

local VectorToOffsetPad = Vector3.new(0, 3, 0)
MatchManagerModule.OnPlayersTeleportedToStartRace = Signal.new()
MatchManagerModule.OnStartedRace = Signal.new()
MatchManagerModule.OnPlayerCrossedFinishLine = Signal.new()
MatchManagerModule.OnLastPlayerCrossedFinishLine = Signal.new()
MatchManagerModule.OnFinishPodiumViewCallback = Signal.new()

MatchManagerModule.CurrentManagerStatus = MatchManagerModule.ManagerStatus.WaitingForTp

function MatchManagerModule:Start()
	ExplorerUtils:GetChildsFromName(TransformsToStarRace, "StartRacePositionModel")
	ExplorerUtils:GetChildsFromName(TransformsToPodium, "PodiumRacePositionModel")
	self.ResteAllVariables()

	local CHECKPOINT_TAG = "Checkpoint"
	local CheckpointtaggedParts = CollectionService:GetTagged(CHECKPOINT_TAG) :: { Model }

	maxIndex = -1
	for _, checkPointArea: Model in ipairs(CheckpointtaggedParts) do
		for __, checkPoint: Instance in ipairs(checkPointArea:GetChildren()) do
			local index = checkPoint:GetAttribute("CheckpointID")
			if index > maxIndex then
				maxIndex = index
			end
		end
	end
end

function MatchManagerModule:AdjustPostionFromObjectsToList(charactersInArea, TransformsToStarRace, offset)
	local index = 1
	for player, rootPart in pairs(charactersInArea) do
		local targetPosition = CFrame.new(offset + TransformsToStarRace[index])
		rootPart.Parent:PivotTo(targetPosition)
		index += 1
		if index > Max_Player_To_Run then
			break
		end
	end
end

function MatchManagerModule:ResteAllVariables()
	listaDePlayers = {}
	listaDeCharacters = {}
	CurrentTimeToTP = 0
	CurrentTimeToStarRace = 0
	currentTimeOnPodium = 0
	QuantityPlayersCrossedFinishLine = 0
end

function MatchManagerModule:WaitingOnPadToStartRace(deltaTime, playersInArea, charactersInArea)
	CurrentTimeToTP += deltaTime
	if CurrentTimeToTP >= Time_Max_To_Await_To_TP then
		listaDePlayers = table.clone(playersInArea)
		listaDeCharacters = table.clone(charactersInArea)

		for _, player in pairs(listaDePlayers) do
			MatchManagerRunController:OnPlayerEnter(player)
		end

		self.CurrentManagerStatus = self.ManagerStatus.WaitingToStarRace
		self:AdjustPostionFromObjectsToList(listaDeCharacters, TransformsToStarRace, VectorToOffsetPad)
		CurrentTimeToTP = 0
		task.wait()
		Net.RaceCountdownStarted.FireList(listaDePlayers)
		self.OnPlayersTeleportedToStartRace:Fire(listaDePlayers)
	end
end

function MatchManagerModule:StartRaceRoutine(deltaTime)
	CurrentTimeToStarRace += deltaTime
	if CurrentTimeToStarRace < GameSettings.RaceSettings.RaceCountdownDuration then
		-- print(`Time To Start Running :{CurrentTimeToStarRace}`)
		return
	end
	--TODO Destravar o player
	self.CurrentManagerStatus = self.ManagerStatus.WaitingForRaceFinish

	for _, player in ipairs(listaDePlayers) do
		print(`Player {player.Name} is ready to race`)
	end

	task.wait()
	self.OnStartedRace:Fire(listaDePlayers)
end

function MatchManagerModule:WaitFinishRace(AreaDetectorFinishRace: AreaDetectorComponent.AreaDetector)
	for index, player: Player in ipairs(AreaDetectorFinishRace.playersInArea) do
		local playerTable = MatchManagerRunController:GetPlayerTable(player)

		if player ~= playerTable.player then
			continue
		end

		if playerTable.lap + 1 > MaxLaps then
			self.OnPlayerCrossedFinishLine:Fire(AreaDetectorFinishRace.playersInArea[index])
			QuantityPlayersCrossedFinishLine += 1

			if #listaDePlayers == QuantityPlayersCrossedFinishLine then
				self.OnLastPlayerCrossedFinishLine:Fire(AreaDetectorFinishRace.playersInArea[index], listaDePlayers)
				self.CurrentManagerStatus = self.ManagerStatus.WaitingForPodium
				task.wait()
				self:AdjustPostionFromObjectsToList(listaDeCharacters, TransformsToPodium, VectorToOffsetPad)

				MatchManagerRunController:CleanAllPlayers()
			end
		else
			if playerTable.checkpoint ~= maxIndex then
				continue
			end

			if playerTable.checkpoint == 0 then
				continue
			end

			playerTable.lap += 1
			playerTable.checkpoint = 0
			MatchManagerRunController:PlayerReachedFinishLine(playerTable.player)
			print(`Player :{playerTable.player} Checkpoint :{playerTable.checkpoint}, Lap :{playerTable.lap}`)
		end
	end
end

function MatchManagerModule:PodiumView(deltaTime)
	currentTimeOnPodium += deltaTime

	if currentTimeOnPodium >= Time_To_Stay_On_Podium then
		currentTimeOnPodium = 0
		self.CurrentManagerStatus = self.ManagerStatus.WaitingForTp
		task.wait()
		self.OnFinishPodiumViewCallback:Fire(listaDePlayers)
		self.ResteAllVariables()
	end
end

function MatchManagerModule:Update(deltaTime, AreaDetectorStartRace: AreaDetectorComponent.AreaDetector, AreaDetectorFinishRace)
	if self.CurrentManagerStatus == self.ManagerStatus.WaitingForTp then
		if #AreaDetectorStartRace.playersInArea >= MinimunPlayersToStart then
			self:WaitingOnPadToStartRace(deltaTime, AreaDetectorStartRace.playersInArea, AreaDetectorStartRace.charactersInArea)
		else
			CurrentTimeToTP = 0
		end
	elseif self.CurrentManagerStatus == self.ManagerStatus.WaitingToStarRace then
		self:StartRaceRoutine(deltaTime)
	elseif self.CurrentManagerStatus == self.ManagerStatus.WaitingForRaceFinish then
		self:WaitFinishRace(AreaDetectorFinishRace)
	elseif self.CurrentManagerStatus == self.ManagerStatus.WaitingForPodium then
		self:PodiumView(deltaTime)
	end
end

return MatchManagerModule
