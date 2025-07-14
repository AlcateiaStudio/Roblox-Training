--// Services //--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Imports //--
local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)
local Signal = require(Packages.Signal)

--// Types //--
type Callback = () -> ()

export type AreaDetector = {
	Instance: Model,
	collider: BasePart,
	areaSize: Vector3,
	partsToDetect: { BasePart },
	isPlayerInArea: boolean,
	Signals: {
		Entered: RBXScriptConnection,
		Left: RBXScriptConnection,
	},
	Callbacks: {
		OnCharacterAdded: ((Model) -> { BasePart })?,
	},
	connections: { RBXScriptConnection },

	Start: (self: AreaDetector) -> (),
	Stop: (self: AreaDetector) -> (),
	RegisterOnCharacterAdded: (self: AreaDetector, callback: (Model) -> { BasePart }) -> (),
}

--// Control //--
local TIME_TO_UPDATE_MAX = 0.05
local timeToUpdate = 0

local localPlayer = Players.LocalPlayer
local character: Model? = nil -- Local player character

--------------------------------------------------------------------------------
--// Component //--
--------------------------------------------------------------------------------
local AreaDetector = Component.new({ Tag = "AreaDetector", Extensions = {} })

--// OverlapParams //--
local areaDetectorOverlapParams = OverlapParams.new()
areaDetectorOverlapParams.FilterType = Enum.RaycastFilterType.Include
areaDetectorOverlapParams.FilterDescendantsInstances = {}

function AreaDetector:Start()
	if not self or not self.Instance then
		warn("No instance found")
		return
	end

	-- print("Starting for AreaDetector", self.Instance)

	assert(self.Instance:IsA("Model"), "AreaDetector must be a model.")

	self.partsToDetect = {} -- Parts to check for collision
	self.isPlayerInArea = false -- Whether local player is in area

	self.Signals = {
		Entered = Signal.new(),
		Left = Signal.new(),
		Stay = Signal.new(),
	}

	self.Callbacks = {}
	self.connections = {}

	-- Handle PrimaryPart loading asynchronously
	task.spawn(function()
		while not self.Instance.PrimaryPart do
			task.wait(1)
		end

		self.collider = self.Instance.PrimaryPart
		self.areaSize = self.collider.Size

		self:_SetupCharacterTracking()
		self:_StartHeartbeat()
	end)
end

function AreaDetector:_SetupCharacterTracking()
	-- Handle current character if it exists
	if localPlayer.Character then
		self:_OnCharacterAdded(localPlayer.Character)
	end

	-- Listen for character spawns
	table.insert(
		self.connections,
		localPlayer.CharacterAdded:Connect(function(newCharacter)
			self:_OnCharacterAdded(newCharacter)
		end)
	)

	-- Listen for character removal
	table.insert(
		self.connections,
		localPlayer.CharacterRemoving:Connect(function()
			self:_OnCharacterRemoving()
		end)
	)
end

function AreaDetector:_StartHeartbeat()
	-- Connect to the step event
	table.insert(
		self.connections,
		RunService.Heartbeat:Connect(function(deltaTime: number)
			timeToUpdate -= deltaTime

			if timeToUpdate <= 0 then
				timeToUpdate = TIME_TO_UPDATE_MAX
				self:_OnHeartbeat()
			end
		end)
	)
end

function AreaDetector:RegisterOnCharacterAdded(callback: (Model) -> { BasePart })
	self.Callbacks.OnCharacterAdded = callback

	-- If character already exists, apply callback
	if character then
		self:_OnCharacterAdded(character)
	end
end

function AreaDetector:Stop()
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end

	self.Signals.Entered:Destroy()
	self.Signals.Left:Destroy()
end

function AreaDetector:_OnCharacterAdded(newCharacter: Model)
	character = newCharacter

	local parts
	if self.Callbacks.OnCharacterAdded then
		parts = self.Callbacks.OnCharacterAdded(newCharacter)
	end

	if not parts or #parts == 0 then
		self.partsToDetect = newCharacter.PrimaryPart and { newCharacter.PrimaryPart } or {}
	else
		self.partsToDetect = parts
	end

	self:_UpdateOverlapParams()
end

function AreaDetector:_OnCharacterRemoving()
	character = nil
	self.partsToDetect = {}
	self.isPlayerInArea = false
	self:_UpdateOverlapParams()
end

function AreaDetector:_UpdateOverlapParams()
	areaDetectorOverlapParams.FilterDescendantsInstances = self.partsToDetect
end

function AreaDetector:_OnHeartbeat()
	if not self.collider or not character or #self.partsToDetect == 0 then
		return
	end

	local nearbyParts = workspace:GetPartBoundsInBox(self.collider:GetPivot(), self.areaSize, areaDetectorOverlapParams)
	local isCurrentlyInArea = false

	-- Check if any of the player's parts are in the area
	for _, part in ipairs(nearbyParts) do
		for _, partToDetect in ipairs(self.partsToDetect) do
			if part == partToDetect then
				isCurrentlyInArea = true
				break
			end
		end
		if isCurrentlyInArea then
			break
		end
	end

	-- Handle state changes
	if isCurrentlyInArea and not self.isPlayerInArea then
		self.isPlayerInArea = true
		self.Signals.Entered:Fire(localPlayer)
	elseif not isCurrentlyInArea and self.isPlayerInArea then
		self.isPlayerInArea = false
		self.Signals.Left:Fire(localPlayer)
	end

	if isCurrentlyInArea and self.isPlayerInArea then
		self.Signals.Stay:Fire(localPlayer)
	end
end

return AreaDetector
