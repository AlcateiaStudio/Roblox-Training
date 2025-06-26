local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local AreaDetectorComponentClass = require(ServerScriptService.Server.Components.AreaDetectorComponent)

local Players_Quantities_To_Start = 1
local Time_Max_To_Await = 3
local CurrentTime = 0

local AreaDetectorTestGameObject
local AreaDetectorComponenteInstance

function OnStart()
	AreaDetectorTestGameObject = workspace:WaitForChild("AreaDetectorTest", 10) :: Model
	assert(AreaDetectorTestGameObject, "AreaDetector not found in workspace")
	AreaDetectorComponentClass:WaitForInstance(AreaDetectorTestGameObject):andThen(function(component)
		AreaDetectorComponenteInstance = component
		RunService.Heartbeat:Connect(_OnHeartbeat)
	end)
end

function AdjustPositionToStarRace()
	for player, rootPart in pairs(AreaDetectorComponenteInstance.charactersInArea) do
		rootPart.Parent:PivotTo(CFrame.new(Vector3.new(0, 1, 0)))
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

OnStart()
