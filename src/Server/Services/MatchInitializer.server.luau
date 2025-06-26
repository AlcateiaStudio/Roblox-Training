local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local AreaDetectorComponentClass = require(ServerScriptService.Server.Components.AreaDetectorComponent)

local Max_Player_To_Run = 4
local Players_Quantities_To_Start = 2
local Time_Max_To_Await = 3
local CurrentTime = 0

local TransformsToStarRace = {}

local AreaDetectorTestGameObject: Model
local AreaDetectorComponenteInstance

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
	CurrentTime += deltaTime
	print(`Increaseing time {CurrentTime}`)
	if CurrentTime >= Time_Max_To_Await then
		AdjustPositionToStarRace()
		print("Reached max time to star race")
		CurrentTime = 0
	end
end

function _OnHeartbeat(deltaTime)
	if #AreaDetectorComponenteInstance.playersInArea >= Players_Quantities_To_Start then
		IncreaseTime(deltaTime)
	else
		CurrentTime = 0
	end
end

function Contains(table, element)
	for _, valor in ipairs(table) do
		if valor == element then
			return true
		end
	end
	return false
end

OnStart()
