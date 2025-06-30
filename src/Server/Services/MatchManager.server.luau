local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local AreaDetectorComponentClass = require(ReplicatedStorage.Shared.Components.AreaDetectorComponent)
local MatchManagerModule = require(ServerScriptService.Server.Services.MatchManagerModule)

local MinimunPlayersToStart = 1

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
	MatchManagerModule.FinishPodium:Connect(FinishPodium)
end

function FinishPodium() end

function WaitFinishRace()
	print("Waiting to finish")
	if #AreaDetectorFinishRaceComponenteInstance.playersInArea >= 1 then
		print(`{AreaDetectorFinishRaceComponenteInstance.playersInArea[1]} Won The Race`)
		MatchManagerModule:FinishRace()
	end
end

function _OnHeartbeat(deltaTime)
	if MatchManagerModule.CurrentManagerStatus == MatchManagerModule.ManagerStatus.WaitingForTp then
		if #AreaDetectorStartRaceComponenteInstance.playersInArea >= MinimunPlayersToStart then
			MatchManagerModule:WaitingOnPadToStartRace(
				deltaTime,
				AreaDetectorStartRaceComponenteInstance.playersInArea,
				AreaDetectorStartRaceComponenteInstance.charactersInArea
			)
		else
			CurrentTimeToTP = 0
		end
	elseif MatchManagerModule.CurrentManagerStatus == MatchManagerModule.ManagerStatus.WaitingToStarRace then
		MatchManagerModule:StartRaceRoutine(deltaTime)
	elseif MatchManagerModule.CurrentManagerStatus == MatchManagerModule.ManagerStatus.WaitingForRaceFinish then
		WaitFinishRace()
	elseif MatchManagerModule.CurrentManagerStatus == MatchManagerModule.ManagerStatus.WaitingForPodium then
		MatchManagerModule:PodiumView(deltaTime)
	end
end

OnStart()
