local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local AreaDetectorComponent = require(ReplicatedStorage.Shared.Components.AreaDetectorComponent)
local ForceApplier = Component.new({ Tag = "ForceApplier", Extensions = {} })

local TweenService = game:GetService("TweenService")

local timeOut = 2
local collisionBodyPartsNames = { "UpperTorso", "Head", "LeftHand", "RightHand", "LeftFoot", "RightFoot" }

local animationDuration = 0.5
local timeToGoBack = 1

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

function ForceApplier:Start()
	AreaDetectorComponent:WaitForInstance(self.Instance, timeOut)
		:andThen(function(component)
			self.areaDetector = component
			self.areaDetector:RegisterOnCharacterAdded(OnCharacterAdded_GetNecessaryPartsToTrack)

			self:SetupAnimationVariables()
			self:SetUpAreaDetectorEvents()
		end)
		:catch(function(err)
			warn("ForceApplier failed to find AreaDetector in instance:", self.Instance, err)

			return nil
		end)
end

function ForceApplier:Stop() end

function ForceApplier:SetUpAreaDetectorEvents()
	self.areaDetector.Signals.Entered:Connect(function(player: Player)
		self:OnPlayerTrigger(player)
	end)
end

function ForceApplier:SetupAnimationVariables()
	local collision: BasePart = self.Instance:FindFirstChild("Collision")
	local endPosition: BasePart = self.Instance:FindFirstChild("EndPosition")

	self.applyingForce = false
	self.positionBase = collision.CFrame.Position
	self.positionApplyingForce = endPosition.CFrame.Position
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

	self:ApplyForce()
end

function ForceApplier:ApplyForce()
	if self.applyingForce == true then
		return
	end

	self.applyingForce = true

	self:MoveToPosition(self.positionApplyingForce, animationDuration)

	wait(animationDuration + timeToGoBack)

	self:MoveToPosition(self.positionBase, animationDuration)

	wait(animationDuration)

	self.applyingForce = false
end

function ForceApplier:MoveToPosition(_position: Vector3, _time: number)
	local collision: BasePart = self.Instance:FindFirstChild("Collision")
	local tweenInfo = TweenInfo.new(_time)
	local endValues = { CFRame = CFrame.new(_position) }

	local tween = TweenService:Create(collision, tweenInfo, endValues)

	tween:Play()
end

return ForceApplier
