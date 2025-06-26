local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local AreaDetectorComponentClass = require(ServerScriptService.Server.Components.AreaDetectorComponent)

local Max_Player_To_Run = 4
local Players_Quantities_To_Start = 1
local Time_Max_To_Await_To_TP = 3
local Time_Max_To_Await_To_Star_Race = 3
local CurrentTimeToTP = 0
local CurrentTimeToStarRace = 0

local TransformsToStarRace = {}

local AreaDetectorTestGameObject: Model
local AreaDetectorComponenteInstance

local waitingForTP = true
local waitingToStarRace = false
local waitinfForRaceFinish = false

function OnStart()
	AreaDetectorTestGameObject = workspace:WaitForChild("AreaDetectorTest", 10) :: Model
	assert(AreaDetectorTestGameObject, "AreaDetector not found in workspace")
	AreaDetectorComponentClass:WaitForInstance(AreaDetectorTestGameObject):andThen(function(component)
		AreaDetectorComponenteInstance = component
		RunService.Heartbeat:Connect(_OnHeartbeat)
	end)
	local startRaceModel = workspace:FindFirstChild("StartRacePositionModel", 10)
	for i, startRacePad: BasePart in ipairs(startRaceModel:GetChildren()) do
		table.insert(TransformsToStarRace, startRacePad.CFrame.Position)
	end
end

function AdjustPositionToStarRace()
	local index = 1
	for player, rootPart in pairs(AreaDetectorComponenteInstance.charactersInArea) do
		local targetPosition = CFrame.new(Vector3.new(0, 1, 0) + TransformsToStarRace[index])
		rootPart.Parent:PivotTo(targetPosition)
		index += 1
		if index > Max_Player_To_Run then
			break
		end
	end
end

function IncreaseTime(deltaTime)
	CurrentTimeToTP += deltaTime
	print(`Increaseing time {CurrentTimeToTP}`)
	if CurrentTimeToTP >= Time_Max_To_Await_To_TP then
		AdjustPositionToStarRace()
		print("Reached max time to star race")
		CurrentTimeToTP = 0
		waitingForTP = false
		waitingToStarRace = true
	end
end

function _OnHeartbeat(deltaTime)
	if waitingForTP == true then
		if #AreaDetectorComponenteInstance.playersInArea >= Players_Quantities_To_Start then
			IncreaseTime(deltaTime)
		else
			CurrentTimeToTP = 0
		end
	elseif waitingToStarRace then
		if CurrentTimeToStarRace < Time_Max_To_Await_To_Star_Race then
			CurrentTimeToStarRace += deltaTime
			print(`Time To Start Running :{CurrentTimeToStarRace}`)
			--TODO CHAMAR HUD 321 e travar o player
			return
		end

		--TODO Destravar o player
		waitingToStarRace = false
		waitinfForRaceFinish = true
	end
end

OnStart()
