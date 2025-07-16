local MatchManagerModule = {}
MatchManagerModule.ManagerStatus = {
	WaitingForTp = 0,
	WaitingToStarRace = 1,
	WaitingForRaceFinish = 2,
	WaitingForPodium = 3,
}

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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
local MinimunPlayersToStart = 2
local MaxLaps = 3

local listaDePlayers = {}
local listaDeCharacters = {}
local TransformsToStartRace = {}
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
	ExplorerUtils:GetChildsFromName(TransformsToStartRace, "StartRacePositionModel")
	ExplorerUtils:GetChildsFromName(TransformsToPodium, "PodiumRacePositionModel")

	table.sort(TransformsToPodium, function(a, b)
		return a:GetAttribute("pos") < b:GetAttribute("pos")
	end)

	self.ResetAllVariables()

	local CHECKPOINT_TAG = "Checkpoint"
	local CheckpointTaggedParts = CollectionService:GetTagged(CHECKPOINT_TAG) :: { Model }

	for _, startRacePosition: BasePart in ipairs(TransformsToStartRace) do
		startRacePosition.Transparency = 1
	end

	for _, podiumPosition: BasePart in ipairs(TransformsToPodium) do
		podiumPosition.Transparency = 1
	end

	maxIndex = -1

	for _, checkPoint: Model in ipairs(CheckpointTaggedParts) do
		local index = checkPoint:GetAttribute("CheckpointID")
		if index > maxIndex then
			maxIndex = index
		end
	end

	if RunService:IsStudio() then
		MinimunPlayersToStart = 1
	end
end

function MatchManagerModule:AdjustPositionFromObjectsToList(charactersInArea, TransformsToStarRace: { BasePart }, offset)
	local index = 1
	for _, rootPart in pairs(charactersInArea) do
		local targetPosition = (CFrame.new(offset + TransformsToStarRace[index].CFrame.Position) * TransformsToStarRace[index].CFrame.Rotation)
		rootPart.Parent:PivotTo(targetPosition)
		index += 1
		if index > Max_Player_To_Run then
			break
		end
	end
end

function MatchManagerModule:ResetAllVariables()
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
		self:AdjustPositionFromObjectsToList(listaDeCharacters, TransformsToStartRace, VectorToOffsetPad)
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

		if playerTable.finished == true then
			continue
		end

		if player ~= playerTable.player then
			continue
		end

		if playerTable.lap + 1 > MaxLaps then
			self.OnPlayerCrossedFinishLine:Fire(AreaDetectorFinishRace.playersInArea[index])
			QuantityPlayersCrossedFinishLine += 1
			playerTable.finished = true

			if #listaDePlayers == QuantityPlayersCrossedFinishLine then
				self.OnLastPlayerCrossedFinishLine:Fire(AreaDetectorFinishRace.playersInArea[index], listaDePlayers)
				self.CurrentManagerStatus = self.ManagerStatus.WaitingForPodium
				task.wait()
				self:AdjustPositionFromObjectsToList(listaDeCharacters, TransformsToPodium, VectorToOffsetPad)
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
		self.ResetAllVariables()
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
