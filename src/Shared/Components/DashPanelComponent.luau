local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local AreaDetectorComponent = require(ReplicatedStorage.Shared.Components.AreaDetectorComponent)
local DashPanel = Component.new({ Tag = "DashPanel", Extensions = {} })

local timeOut = 2
local collisionBodyPartsNames = { "LeftFoot", "RightFoot" }

type DashStateChangedCallback = (_isDashEnabled: boolean) -> ()

local dashStateChangedCallback: DashStateChangedCallback? = nil

local playersInArea = {}

local function OnCharacterAdded_GetNecessaryPartsToTrack(player: Player, character: Model)
	local partsToTrack: { BasePart } = {}

	for i, v in pairs(collisionBodyPartsNames) do
		local collisionBodyPart = character:FindFirstChild(v)

		if collisionBodyPart:IsA("BasePart") then
			table.insert(partsToTrack, collisionBodyPart)
		else
			warn(`O objeto com nome \"{v}\" nao e uma BasePart!`)
		end
	end

	return partsToTrack
end

local function CanCollideWithPlayer(player: Player)
	if player ~= localPlayer then
		return false
	end

	local character: Model? = player.Character

	if character == nil then
		warn("Player character not found for player:", player.Name)

		return false
	end

	if character.PrimaryPart == nil then
		warn("Primary part not found for character:", character.Name)

		return false
	end

	return true
end

function DashPanel:Start()
	AreaDetectorComponent:WaitForInstance(self.Instance, timeOut)
		:andThen(function(component)
			self.areaDetector = component
			self.areaDetector:RegisterOnCharacterAdded(OnCharacterAdded_GetNecessaryPartsToTrack)

			self:SetUpAreaDetectorEvents()
		end)
		:catch(function(err)
			warn("DashPanel failed to find AreaDetector in instance:", self.Instance, err)

			return nil
		end)
end

function DashPanel:Stop() end

function DashPanel:SetUpAreaDetectorEvents()
	self.areaDetector.Signals.Entered:Connect(function(player: Player)
		self:OnPlayerEnter(player)
	end)

	self.areaDetector.Signals.Left:Connect(function(player: Player)
		self:OnPlayerExit(player)
	end)
end

function DashPanel:RegisterDashStateChangedCallback(callback: DashStateChangedCallback)
	dashStateChangedCallback = callback
end

function DashPanel:OnPlayerEnter(player: Player)
	if CanCollideWithPlayer(player) == false then
		return
	end

	if playersInArea[player] == nil then
		playersInArea[player] = 1

		if dashStateChangedCallback ~= nil then
			dashStateChangedCallback(true)
		end
	else
		playersInArea[player] += 1
	end
end

function DashPanel:OnPlayerExit(player: Player)
	if CanCollideWithPlayer(player) == false then
		return
	end

	if playersInArea[player] ~= nil then
		playersInArea[player] -= 1

		if playersInArea[player] <= 0 then
			playersInArea[player] = nil

			if dashStateChangedCallback ~= nil then
				dashStateChangedCallback(false)
			end
		end
	end
end

return DashPanel
