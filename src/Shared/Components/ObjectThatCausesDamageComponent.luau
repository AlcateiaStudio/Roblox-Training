local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)

local AreaDetectorComponent = require(ReplicatedStorage.Shared.Components.AreaDetectorComponent)
local ObjectThatCausesDamage = Component.new({ Tag = "ObjectThatCausesDamage", Extensions = {} })

local timeOut = 2
local collisionBodyPartsNames = { "UpperTorso", "Head", "LeftHand", "RightHand", "LeftFoot", "RightFoot" }

local knockBackSpeed = 40

type CauseDamageCallback = (_knockBackSpeed: number, _knockBackDirection: Vector3) -> ()

local causeDamageCallback: CauseDamageCallback? = nil

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

function ObjectThatCausesDamage:Start()
	AreaDetectorComponent:WaitForInstance(self.Instance, timeOut)
		:andThen(function(component)
			self.areaDetector = component
			self.areaDetector:RegisterOnCharacterAdded(OnCharacterAdded_GetNecessaryPartsToTrack)

			self:SetUpAreaDetectorEvents()
		end)
		:catch(function(err)
			warn("ObjectThatCausesDamage failed to find AreaDetector in instance:", self.Instance, err)

			return nil
		end)
end

function ObjectThatCausesDamage:Stop() end

function ObjectThatCausesDamage:SetUpAreaDetectorEvents()
	self.areaDetector.Signals.Entered:Connect(function(player: Player)
		self:CauseDamage(player)
	end)
end

function ObjectThatCausesDamage:CauseDamage(player: Player)
	local character: Model? = player.Character

	if character == nil then
		warn("Player character not found for player:", player.Name)

		return
	end

	if character.PrimaryPart == nil then
		warn("Primary part not found for character:", character.Name)

		return
	end

	local collider: BasePart = self.areaDetector.collider
	local knockBackDirection: Vector3 = character.PrimaryPart.CFrame.Position - collider.CFrame.Position

	if causeDamageCallback ~= nil then
		causeDamageCallback(knockBackSpeed, knockBackDirection)
	end
end

function ObjectThatCausesDamage:RegisterOnDamageCallback(callback: CauseDamageCallback)
	causeDamageCallback = callback
end

return ObjectThatCausesDamage
