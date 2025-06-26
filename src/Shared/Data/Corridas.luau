export type Corrida = {
	Nome: string,
	TrackImageID: string,
	LargadaPosition: UDim2,
	Bounds: ObjectValue?,
}

local CorridasReferencesFolder = workspace:WaitForChild("Corridas", 2) :: Folder?

if not CorridasReferencesFolder then
	warn("CorridasReferencesFolder not found in workspace. Please ensure it exists.")
	return {}
end

local function GetCorridaFolder(corridaName: string)
	local folder = CorridasReferencesFolder:FindFirstChild(corridaName)
	if not folder then
		warn(`Corrida folder '{corridaName}' not found in CorridasReferencesFolder.`)
		return nil
	end

	if not folder:IsA("Folder") then
		warn(`'{corridaName}' is not a Folder.`)
		return nil
	end

	return folder
end

local function GetBounds(corridaFolder: Folder): ObjectValue?
	local boundsPart = corridaFolder:FindFirstChild("Bounds")
	if not boundsPart then
		warn(`Bounds part not found in '{corridaFolder.Name}'.`)
		return nil
	end

	if not boundsPart:IsA("ObjectValue") then
		warn(`'{boundsPart.Name}' is not an ObjectValue.`)
		return nil
	end

	return boundsPart
end

local function CreateCorrida(nome: string, trackImageID: string, largadaPosition: UDim2): Corrida
	return {
		Nome = nome,
		TrackImageID = trackImageID,
		LargadaPosition = largadaPosition,
		Bounds = GetBounds(GetCorridaFolder(nome)),
	}
end

local Corridas = {
	CorridaTabajara = CreateCorrida("Tabajara Track", "rbxassetid://1234567890", UDim2.new(0.5, 0, 0.5, 0)),
}

return Corridas
