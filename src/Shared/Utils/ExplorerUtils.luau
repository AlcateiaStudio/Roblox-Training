local ExplorerUtils = {}

function ExplorerUtils:GetChildsFromName(TransformsToStarRace, name: string)
	local part = workspace:WaitForChild("Tabajara Track"):FindFirstChild(name, 10)
	for i, basePart: BasePart in ipairs(part:GetChildren()) do
		table.insert(TransformsToStarRace, basePart.CFrame.Position)
	end
end

return ExplorerUtils
