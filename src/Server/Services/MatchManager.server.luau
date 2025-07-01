local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local AreaDetectorComponentClass = require(ReplicatedStorage.Shared.Components.AreaDetectorComponent)
local CharacterUtils = require(ReplicatedStorage.Shared.Utils.CharacterUtils)
local MatchManagerModule = require(ServerScriptService.Server.Services.MatchManagerModule)

local Net = require(ServerScriptService.Server.Net)

local AreaDetectorStartRaceComponenteInstance
local AreaDetectorFinishRaceComponenteInstance

function OnStart()
	local AreaDetectorStartRaceGameObject: Model = workspace:WaitForChild("AreaDetectorRunStart", 10) :: Model
	assert(AreaDetectorStartRaceGameObject, "AreaDetector not found in workspace")
	AreaDetectorComponentClass:WaitForInstance(AreaDetectorStartRaceGameObject):andThen(function(component)
		AreaDetectorStartRaceComponenteInstance = component
		RunService.Heartbeat:Connect(_OnHeartbeat)
	end)

	local AreaDetectorFinishRaceGameObject: Model = workspace:WaitForChild("AreaDetectorRunFinish", 10) :: Model
	assert(AreaDetectorFinishRaceGameObject, "AreaDetector not found in workspace")
	AreaDetectorComponentClass:WaitForInstance(AreaDetectorFinishRaceGameObject):andThen(function(component)
		AreaDetectorFinishRaceComponenteInstance = component
	end)

	MatchManagerModule:Start()

	MatchManagerModule.OnPlayersTeleportedToStartRace:Connect(OnCharactersOnPositionToStartRace)
	MatchManagerModule.OnStartedRace:Connect(OnStartRace)
	MatchManagerModule.OnPlayerCrossedFinishLine:Connect(OnPlayerCrossedFinishLinde)
	MatchManagerModule.OnLastPlayerCrossedFinishLine:Connect(OnLastPlayerCrossedFinishLinde)
	MatchManagerModule.OnFinishPodiumViewCallback:Connect(OnFinishPodium)
end

function OnCharactersOnPositionToStartRace(listaDeCharacters)
	ToggleCharacterLock(listaDeCharacters, true)
end

function OnStartRace(listaDePlayers, listaDeCharacters)
	print("Race Will Start")
	Net.RaceStarted.FireList(listaDePlayers)
	ToggleCharacterLock(listaDeCharacters, false)
end

function OnPlayerCrossedFinishLinde(player)
	print(`Player {player} Crossed`)
end
function OnLastPlayerCrossedFinishLinde(player, listaDeCharacters)
	print(`Player {player} Crossed On Last`)
	ToggleCharacterLock(listaDeCharacters, true)
end

function OnFinishPodium(listaDePlayers, listaDeCharacters)
	print("Finished Podium view")
	Net.RaceFinished.FireList(listaDePlayers)
	ToggleCharacterLock(listaDeCharacters, false)
end

function ToggleCharacterLock(listaDeCharacters, lock)
	for character, _ in pairs(listaDeCharacters) do
		if lock == true then
			CharacterUtils:LockCharacter(character.character)
		else
			CharacterUtils:UnlockCharacter(character.character)
		end
	end
end

function _OnHeartbeat(deltaTime)
	MatchManagerModule:Update(
		deltaTime,
		AreaDetectorStartRaceComponenteInstance,
		AreaDetectorFinishRaceComponenteInstance
	)
end

OnStart()
