local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local AreaDetectorComponent = require(ReplicatedStorage.Shared.Components.AreaDetectorComponent)
local JumpPad = Component.new({ Tag = "JumpPad", Extensions = {} })

local timeOut = 2
local collisionBodyPartsNames = { "LeftFoot", "RightFoot" }

type SetJumpCallback = (_jumpHeight: number) -> ()

local setJumpCallback: SetJumpCallback? = nil

local jumpHeight = 30

local function OnCharacterAdded_GetNecessaryPartsToTrack(_: Player, character: Model)
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

function JumpPad:Start()
	AreaDetectorComponent:WaitForInstance(self.Instance, timeOut)
		:andThen(function(component)
			self.areaDetector = component
			self.areaDetector:RegisterOnCharacterAdded(OnCharacterAdded_GetNecessaryPartsToTrack)

			self:SetUpAreaDetectorEvents()
			self:MakeCollidersTransparent()
		end)
		:catch(function(err)
			warn("JumpPad failed to find AreaDetector in instance:", self.Instance, err)

			return nil
		end)
end

function JumpPad:Stop() end

function JumpPad:SetUpAreaDetectorEvents()
	self.areaDetector.Signals.Entered:Connect(function(player: Player)
		self:SetJump(player)
	end)
end

function JumpPad:MakeCollidersTransparent()
	local collision: BasePart = self.Instance:FindFirstChild("Collision")

	collision.Transparency = 1
end

function JumpPad:RegisterSetJumpCallback(callback: SetJumpCallback)
	setJumpCallback = callback
end

function JumpPad:SetJump(player: Player)
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

	if setJumpCallback ~= nil then
		setJumpCallback(jumpHeight)
	end
end

return JumpPad
