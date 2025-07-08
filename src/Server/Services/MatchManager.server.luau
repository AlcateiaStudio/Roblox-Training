local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local AreaDetectorComponentClass = require(ReplicatedStorage.Shared.Components.AreaDetectorComponent)
local MatchManagerInfosModule = require(ServerScriptService.Server.Services.MatchManagerInfo)
local MatchManagerModule = require(ServerScriptService.Server.Services.MatchManagerModule)

local Net = require(ServerScriptService.Server.Net)

local AreaDetectorStartRaceComponenteInstance
local AreaDetectorFinishRaceComponenteInstance

function OnStart()
	local AreaDetectorStartRaceGameObject: Model = workspace:WaitForChild("Tabajara Track"):WaitForChild("AreaDetectorRunStart", 10) :: Model
	assert(AreaDetectorStartRaceGameObject, "AreaDetector not found in workspace")
	AreaDetectorComponentClass:WaitForInstance(AreaDetectorStartRaceGameObject):andThen(function(component)
		AreaDetectorStartRaceComponenteInstance = component
		RunService.Heartbeat:Connect(_OnHeartbeat)
	end)

	local AreaDetectorFinishRaceGameObject: Model = workspace:WaitForChild("Tabajara Track"):WaitForChild("AreaDetectorRunFinish", 10) :: Model
	assert(AreaDetectorFinishRaceGameObject, "AreaDetector not found in workspace")
	AreaDetectorComponentClass:WaitForInstance(AreaDetectorFinishRaceGameObject):andThen(function(component)
		AreaDetectorFinishRaceComponenteInstance = component
	end)

	MatchManagerModule:Start()
	MatchManagerInfosModule:Start()
	MatchManagerModule.OnPlayersTeleportedToStartRace:Connect(OnCharactersOnPositionToStartRace)
	MatchManagerModule.OnStartedRace:Connect(OnStartRace)
	MatchManagerModule.OnPlayerCrossedFinishLine:Connect(OnPlayerCrossedFinishLinde)
	MatchManagerModule.OnLastPlayerCrossedFinishLine:Connect(OnLastPlayerCrossedFinishLinde)
	MatchManagerModule.OnFinishPodiumViewCallback:Connect(OnFinishPodium)
end

function OnCharactersOnPositionToStartRace(listaDePlayers)
	ToggleCharacterLock(listaDePlayers, true)
end

function OnStartRace(listaDePlayers)
	print("Race Will Start")
	ToggleCharacterLock(listaDePlayers, false)
	Net.RaceStarted.FireList(listaDePlayers)
end

function OnPlayerCrossedFinishLinde(player)
	print(`Player {player} Crossed`)
end
function OnLastPlayerCrossedFinishLinde(player, listaDePlayers)
	print(`Player {player} Crossed On Last`)
	ToggleCharacterLock(listaDePlayers, true)
end

function OnFinishPodium(listaDePlayers)
	print("Finished Podium view")
	ToggleCharacterLock(listaDePlayers, false)
	Net.RaceFinished.FireList(listaDePlayers)
end

function ToggleCharacterLock(listaDePlayers, lock)
	local playerStateValue = 0
	if lock == true then
		playerStateValue = 2
	end
	Net.UpdatePlayerState.FireList(listaDePlayers, playerStateValue)
end

function _OnHeartbeat(deltaTime)
	MatchManagerModule:Update(deltaTime, AreaDetectorStartRaceComponenteInstance, AreaDetectorFinishRaceComponenteInstance)
end

OnStart()
