local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local AreaDetectorComponentClass = require(ReplicatedStorage.Shared.Components.AreaDetectorComponent)
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

	MatchManagerModule.OnPlayersTeleportedToStartRace:Connect(OnFinishPodium)
	MatchManagerModule.OnStartedRace:Connect(OnStartRace)
	MatchManagerModule.OnPlayerCrossedFinishLine:Connect(OnPlayerCrossedFinishLinde)
	MatchManagerModule.OnLastPlayerCrossedFinishLine:Connect(OnLastPlayerCrossedFinishLinde)
	MatchManagerModule.OnFinishPodiumViewCallback:Connect(OnFinishPodium)
end

function OnStartRace(listaDePlayers)
	print("Race Will Start")
	Net.RaceStarted.FireList(listaDePlayers)
end

function OnPlayerCrossedFinishLinde(player)
	print(`Player {player} Crossed`)
end
function OnLastPlayerCrossedFinishLinde(player)
	print(`Player {player} Crossed On Last`)
end

function OnFinishPodium()
	print("Finished Podium view")
end

function _OnHeartbeat(deltaTime)
	MatchManagerModule:Update(
		deltaTime,
		AreaDetectorStartRaceComponenteInstance,
		AreaDetectorFinishRaceComponenteInstance
	)
end

OnStart()
