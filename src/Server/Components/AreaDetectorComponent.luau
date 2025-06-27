--// Services //--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--// Imports //--
local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)
local Signal = require(Packages.Signal)

--// Constants //--
local UPDATE_RATE = 6

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
		OnCharacterAdded = Instance.new("BindableFunction")
	}

	-- Check for existing players
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character or player.CharacterAdded:Wait()
		self:_OnCharacterAdded(player, character)
	end

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

	-- Connect to the step event at a set frame rate
	local frame = 0
	table.insert(
		self.connections,
		RunService.Heartbeat:Connect(function(...)
			frame = (frame + 1) % UPDATE_RATE
			if frame ~= 0 then
				return
			end
			self:_OnHeartbeat(...)
		end)
	)
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
	local parts = self.Signals.OnCharacterAdded:Invoke(player, character)
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
		table.insert(filterList, parts)
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
