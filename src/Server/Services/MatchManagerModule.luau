local MatchManagerModule = {}

local Max_Player_To_Run = 4

function MatchManagerModule:GetPadsStartRace(TransformsToStarRace)
	local startRaceModel = workspace:FindFirstChild("StartRacePositionModel", 10)
	for i, startRacePad: BasePart in ipairs(startRaceModel:GetChildren()) do
		table.insert(TransformsToStarRace, startRacePad.CFrame.Position)
	end
end

function MatchManagerModule:AdjustPositionToStarRace(AreaDetectorStartRaceComponenteInstance, TransformsToStarRace)
	local index = 1
	for player, rootPart in pairs(AreaDetectorStartRaceComponenteInstance.charactersInArea) do
		local targetPosition = CFrame.new(Vector3.new(0, 1, 0) + TransformsToStarRace[index])
		rootPart.Parent:PivotTo(targetPosition)
		index += 1
		if index > Max_Player_To_Run then
			break
		end
	end
end

return MatchManagerModule
