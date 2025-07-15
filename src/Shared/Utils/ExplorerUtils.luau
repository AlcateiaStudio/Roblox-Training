local ExplorerUtils = {}

function ExplorerUtils:GetChildsFromName(tableToAddTo, name: string)
	local part = workspace:WaitForChild("Corridas"):WaitForChild("Tabajara Track"):FindFirstChild(name, 10)

	for _, basePart: BasePart in ipairs(part:GetChildren()) do
		table.insert(tableToAddTo, basePart)
	end
end

return ExplorerUtils
