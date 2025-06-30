local MatchManagerModule = {}
MatchManagerModule.ManagerStatus = {
	WaitingForTp = 0,
	WaitingToStarRace = 1,
	WaitingForRaceFinish = 2,
	WaitingForPodium = 3,
}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Net = require(ServerScriptService.Server.Net)

local Max_Player_To_Run = 4
local Time_Max_To_Await_To_Star_Race = 3
local Time_To_Stay_On_Podium = 5
local Time_Max_To_Await_To_TP = 3

local listaDePlayers = {}
local listaDeCharacters = {}
local TransformsToStarRace = {}
local TransformsToPodium = {}

local CurrentTimeToTP = 0
local CurrentTimeToStarRace = 0
local currentTimeOnPodium = 0

MatchManagerModule.FinishPodium = Signal.new()
MatchManagerModule.CurrentManagerStatus = MatchManagerModule.ManagerStatus.WaitingForTp

function MatchManagerModule:Start()
	self:GetChildsFromName(TransformsToStarRace, "StartRacePositionModel")
	self:GetChildsFromName(TransformsToPodium, "PodiumRacePositionModel")
end

function MatchManagerModule:GetChildsFromName(TransformsToStarRace, name: string)
	local startRaceModel = workspace:FindFirstChild(name, 10)
	for i, startRacePad: BasePart in ipairs(startRaceModel:GetChildren()) do
		table.insert(TransformsToStarRace, startRacePad.CFrame.Position)
	end
end

function MatchManagerModule:AdjustPostionFromObjectsToList(charactersInArea, TransformsToStarRace)
	local index = 1
	for player, rootPart in pairs(charactersInArea) do
		local targetPosition = CFrame.new(Vector3.new(0, 1, 0) + TransformsToStarRace[index])
		rootPart.Parent:PivotTo(targetPosition)
		index += 1
		if index > Max_Player_To_Run then
			break
		end
	end
end

function MatchManagerModule:PodiumView(deltaTime)
	currentTimeOnPodium += deltaTime

	if currentTimeOnPodium >= Time_To_Stay_On_Podium then
		currentTimeOnPodium = 0
		self.CurrentManagerStatus = self.ManagerStatus.WaitingForTp
		self.FinishPodium:Fire()
	end
end

function MatchManagerModule:WaitingOnPadToStartRace(deltaTime, playersInArea, charactersInArea)
	CurrentTimeToTP += deltaTime
	if CurrentTimeToTP >= Time_Max_To_Await_To_TP then
		listaDePlayers = table.clone(playersInArea)
		listaDeCharacters = table.clone(charactersInArea)

		self.CurrentManagerStatus = self.ManagerStatus.WaitingToStarRace
		self:AdjustPostionFromObjectsToList(listaDeCharacters, TransformsToStarRace)
		CurrentTimeToTP = 0

		print("Reached max time to start race")
	end
end

function MatchManagerModule:FinishRace()
	self.CurrentManagerStatus = self.ManagerStatus.WaitingForPodium
	self:AdjustPostionFromObjectsToList(listaDeCharacters, TransformsToPodium)
end

function MatchManagerModule:StartRaceRoutine(deltaTime)
	CurrentTimeToStarRace += deltaTime
	if CurrentTimeToStarRace < Time_Max_To_Await_To_Star_Race then
		--TODO CHAMAR HUD
		print(`Time To Start Running :{CurrentTimeToStarRace}`)
		return
	end
	--TODO Destravar o player
	self.CurrentManagerStatus = self.ManagerStatus.WaitingForRaceFinish

	for _, player in ipairs(listaDePlayers) do
		print(`Player {player.Name} is ready to race`)
	end

	Net.RaceStarted.FireList(listaDePlayers)
end

return MatchManagerModule
