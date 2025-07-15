local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Client.Net)

local Component = require(ReplicatedStorage.Packages.Component)

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local AreaDetectorComponent = require(ReplicatedStorage.Client.Components.ClientAreaDetector)
local ForceApplier = Component.new({ Tag = "ForceApplier", Extensions = {} })

local timeOut = 2
local collisionBodyPartsNames = { "UpperTorso", "Head", "LeftHand", "RightHand", "LeftFoot", "RightFoot" }

local function OnCharacterAdded_GetNecessaryPartsToTrack(character: Model)
	local partsToTrack: { BasePart } = {}

	for _, v in pairs(collisionBodyPartsNames) do
		local collisionBodyPart = character:FindFirstChild(v)

		if collisionBodyPart:IsA("BasePart") then
			table.insert(partsToTrack, collisionBodyPart)
		else
			warn(`O objeto com nome \"{v}\" nao e uma BasePart!`)
		end
	end

	return partsToTrack
end

function ForceApplier:Start()
	AreaDetectorComponent:WaitForInstance(self.Instance, timeOut)
		:andThen(function(component: AreaDetectorComponent.AreaDetector)
			self.areaDetector = component
			component:RegisterOnCharacterAdded(OnCharacterAdded_GetNecessaryPartsToTrack)

			self.ID = self.Instance:GetAttribute("ID")

			self:SetUpAreaDetectorEvents()
		end)
		:catch(function(err)
			warn("ForceApplier failed to find AreaDetector in instance:", self.Instance, err)

			return nil
		end)
end

function ForceApplier:Stop() end

function ForceApplier:SetUpAreaDetectorEvents()
	self.areaDetector.Signals.Stay:Connect(function()
		self:OnPlayerTrigger(localPlayer)
	end)
end

function ForceApplier:OnPlayerTrigger(player: Player)
	if player ~= localPlayer then
		return
	end

	local character: Model? = player.Character

	if character == nil then
		warn("Player character not found for player:", player.Name)

		return
	end

	if character.PrimaryPart == nil then
		warn("Primary part not found for character:", character.Name)

		return
	end

	Net.PlayerCollidedWithForceApplier.Fire(self.ID)
end

return ForceApplier
