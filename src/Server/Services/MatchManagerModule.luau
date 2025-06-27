local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

local MatchManagerModule = {}

local Max_Player_To_Run = 4
MatchManagerModule.FinishPodium = Signal.new()

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

local Time_To_Stay_On_Podium = 5
local currentTimeOnPodium = 0

function MatchManagerModule:PodiumView(deltaTime)
	currentTimeOnPodium += deltaTime

	if currentTimeOnPodium >= Time_To_Stay_On_Podium then
		currentTimeOnPodium = 0
		MatchManagerModule.FinishPodium:Fire()
	end
end

return MatchManagerModule
