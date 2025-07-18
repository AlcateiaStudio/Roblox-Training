local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local AreaDetectorComponent = require(ServerScriptService.Server.Components.ServerAreaDetector)
local MatchManagerInfosModule = require(ServerScriptService.Server.Services.MatchManagerInfo)
local MatchManagerModule = require(ServerScriptService.Server.Services.MatchManagerModule)
local MatchManagerRunController = require(ServerScriptService.Server.Services.MatchManagerRunController)

local Net = require(ServerScriptService.Server.Net)

local AreaDetectorStartRaceComponenteInstance
local AreaDetectorFinishRaceComponenteInstance

local function ToggleCharacterLock(listaDePlayers, lock)
	local playerStateValue = 0
	if lock == true then
		playerStateValue = 2
	end
	Net.UpdatePlayerState.FireList(listaDePlayers, playerStateValue)
end

local function OnCharactersOnPositionToStartRace(listaDePlayers)
	ToggleCharacterLock(listaDePlayers, true)
end

local function OnStartRace(listaDePlayers)
	print("Race Will Start")
	ToggleCharacterLock(listaDePlayers, false)
	Net.RaceStarted.FireList(listaDePlayers)
end

local function OnPlayerCrossedFinishLinde(player)
	print(`Player {player} Crossed`)
end
local function OnLastPlayerCrossedFinishLinde(player, listaDePlayers)
	print(`Player {player} Crossed On Last`)
	ToggleCharacterLock(listaDePlayers, true)
end

local function OnFinishPodium(listaDePlayers)
	print("Finished Podium view")
	ToggleCharacterLock(listaDePlayers, false)
	local playersInOrder = {}
	local temp = MatchManagerRunController:GetAllPlayersTable()
	for _, playerTable in pairs(temp) do
		table.insert(playersInOrder, playerTable.player)
	end

	Net.RaceFinished.FireList(playersInOrder)
	MatchManagerRunController:CleanAllPlayers()
end

local function _OnHeartbeat(deltaTime)
	MatchManagerModule:Update(deltaTime, AreaDetectorStartRaceComponenteInstance, AreaDetectorFinishRaceComponenteInstance)
end

local function OnStart()
	local AreaDetectorStartRaceModel: Model = workspace.Corridas["Tabajara Track"]:WaitForChild("AreaDetectorRunStart", 2) :: Model
	assert(AreaDetectorStartRaceModel, "AreaDetector not found in workspace")
	AreaDetectorComponent:WaitForInstance(AreaDetectorStartRaceModel):andThen(function(component: AreaDetectorComponent.AreaDetector)
		AreaDetectorStartRaceComponenteInstance = component
		RunService.Heartbeat:Connect(_OnHeartbeat)
	end)

	local AreaDetectorFinishRaceModel: Model = workspace.Corridas["Tabajara Track"]:WaitForChild("AreaDetectorRunFinish", 2) :: Model
	assert(AreaDetectorFinishRaceModel, "AreaDetector not found in workspace")
	AreaDetectorComponent:WaitForInstance(AreaDetectorFinishRaceModel):andThen(function(component: AreaDetectorComponent.AreaDetector)
		AreaDetectorFinishRaceComponenteInstance = component
	end)

	local areaDetectorStartRaceModelCollision = AreaDetectorStartRaceModel:FindFirstChild("Collision") :: BasePart
	local areaDetectorFinishRaceModelCollision = AreaDetectorFinishRaceModel:FindFirstChild("Collision") :: BasePart

	areaDetectorStartRaceModelCollision.Transparency = 1
	areaDetectorFinishRaceModelCollision.Transparency = 1

	MatchManagerModule:Start()
	MatchManagerInfosModule:Start()
	MatchManagerRunController:Start()
	MatchManagerModule.OnPlayersTeleportedToStartRace:Connect(OnCharactersOnPositionToStartRace)
	MatchManagerModule.OnStartedRace:Connect(OnStartRace)
	MatchManagerModule.OnPlayerCrossedFinishLine:Connect(OnPlayerCrossedFinishLinde)
	MatchManagerModule.OnLastPlayerCrossedFinishLine:Connect(OnLastPlayerCrossedFinishLinde)
	MatchManagerModule.OnFinishPodiumViewCallback:Connect(OnFinishPodium)
end

OnStart()
