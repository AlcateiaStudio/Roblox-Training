local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local AreaDetectorComponentClass = require(ServerScriptService.Server.Components.AreaDetectorComponent)

local MatchManagerModule = require(ServerScriptService.Server.Services.MatchManagerModule)

local Players_Quantities_To_Start = 1
local Time_Max_To_Await_To_TP = 3
local Time_Max_To_Await_To_Star_Race = 3
local CurrentTimeToTP = 0
local CurrentTimeToStarRace = 0

local TransformsToStarRace = {}

local AreaDetectorStartRaceGameObject: Model
local AreaDetectorStartRaceComponenteInstance

local waitingForTP = true
local waitingToStarRace = false
local waitinfForRaceFinish = false

function OnStart()
	AreaDetectorStartRaceGameObject = workspace:WaitForChild("AreaDetectorTest", 10) :: Model
	assert(AreaDetectorStartRaceGameObject, "AreaDetector not found in workspace")
	AreaDetectorComponentClass:WaitForInstance(AreaDetectorStartRaceGameObject):andThen(function(component)
		AreaDetectorStartRaceComponenteInstance = component
		RunService.Heartbeat:Connect(_OnHeartbeat)
	end)
	MatchManagerModule:GetPadsStartRace(TransformsToStarRace)
end

function IncreaseTime(deltaTime)
	CurrentTimeToTP += deltaTime
	print(`Increaseing time {CurrentTimeToTP}`)
	if CurrentTimeToTP >= Time_Max_To_Await_To_TP then
		MatchManagerModule:AdjustPositionToStarRace(AreaDetectorStartRaceComponenteInstance, TransformsToStarRace)
		print("Reached max time to star race")
		CurrentTimeToTP = 0
		waitingForTP = false
		waitingToStarRace = true
	end
end

function StartRaceRoutine(deltaTime)
	CurrentTimeToStarRace += deltaTime
	if CurrentTimeToStarRace < Time_Max_To_Await_To_Star_Race then
		--TODO CHAMAR HUD
		print(`Time To Start Running :{CurrentTimeToStarRace}`)
		return
	end
	--TODO Destravar o player
	waitingToStarRace = false
	waitinfForRaceFinish = true
end

function _OnHeartbeat(deltaTime)
	if waitingForTP == true then
		if #AreaDetectorStartRaceComponenteInstance.playersInArea >= Players_Quantities_To_Start then
			IncreaseTime(deltaTime)
		else
			CurrentTimeToTP = 0
		end
	elseif waitingToStarRace then
		StartRaceRoutine(deltaTime)
	end
end

OnStart()
