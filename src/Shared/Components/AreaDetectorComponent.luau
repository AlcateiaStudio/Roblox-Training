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

--// Control //--
local TIME_TO_UPDATE_MAX = 0.05
local timeToUpdate = 0

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
		warn("[AreaDetector] - No instance found")
		return
	end

	print("Starting for AreaDetector", self.Instance.Name)

	assert(self.Instance:IsA("Model"), "AreaDetector must be a model.")
	assert(self.Instance.PrimaryPart, "No primary part found in AreaDetector instance.")

	self.collider = self.Instance.PrimaryPart
	self.areaSize = self.collider.Size

	self.charactersToDetect = {} -- All root parts to check
	self.charactersInArea = {} -- Characters found in the area
	self.playersInArea = {} -- Players found in the area

	self.Signals = {
		Entered = Signal.new(),
		Left = Signal.new(),
	}

	self.Callbacks = {}

	-- Check for existing players
	self:UpdateExistingPlayers()

	self.connections = {}

	table.insert(
		self.connections,
		Players.PlayerAdded:Connect(function(player)
			player.CharacterAdded:Connect(function(character)
				self:_OnCharacterAdded(player, character)
			end)
		end)
	)

	table.insert(
		self.connections,
		Players.PlayerRemoving:Connect(function(player)
			self.charactersToDetect[player] = nil
		end)
	)

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

function AreaDetector:UpdateExistingPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character or player.CharacterAdded:Wait()
		self:_OnCharacterAdded(player, character)
	end
end

function AreaDetector:RegisterOnCharacterAdded(callback: (Player, Model) -> { BasePart })
	if not self.Signals.OnCharacterAdded then
		self.Callbacks.OnCharacterAdded = callback

		self:UpdateExistingPlayers()
	end
end

function AreaDetector:Stop()
	for _, connection in ipairs(self.connections) do
		print(`Disconnecting {connection}`)
		connection:Disconnect()
	end

	self.Signals.Entered:Destroy()
	self.Signals.Left:Destroy()
	self.Signals.OnCharacterAdded:Destroy()
end

function AreaDetector:_OnCharacterAdded(player: Player, character: Model)
	local parts
	if self.Callbacks.OnCharacterAdded then
		parts = self.Callbacks.OnCharacterAdded(player, character)
	end
	if not parts or #parts == 0 then
		self.charactersToDetect[player] = { character.PrimaryPart }
	else
		self.charactersToDetect[player] = parts
	end
	self:_UpdateOverlapParams()
end

function AreaDetector:_UpdateOverlapParams()
	local filterList = {}
	for _, parts in pairs(self.charactersToDetect) do
		for _, part in ipairs(parts) do
			table.insert(filterList, part)
		end
	end
	areaDetectorOverlapParams.FilterDescendantsInstances = filterList
end

function AreaDetector:_OnHeartbeat()
	if not self.collider then
		warn("No collider part set.")
		return
	end

	local nearbyParts = workspace:GetPartBoundsInBox(self.collider:GetPivot(), self.areaSize, areaDetectorOverlapParams)
	local currentPlayersInArea = {}

	for _, part in ipairs(nearbyParts) do
		for player, parts in pairs(self.charactersToDetect) do
			for _, partToDetect in ipairs(parts) do
				if part == partToDetect then
					currentPlayersInArea[player] = partToDetect
					if not self.charactersInArea[player] then
						self.charactersInArea[player] = partToDetect
						table.insert(self.playersInArea, player)
						self.Signals.Entered:Fire(player)
					end
				end
			end
		end
	end

	for player, _ in pairs(self.charactersInArea) do
		if not currentPlayersInArea[player] then
			self.charactersInArea[player] = nil
			table.remove(self.playersInArea, table.find(self.playersInArea, player))
			self.Signals.Left:Fire(player)
		end
	end
end

return AreaDetector
