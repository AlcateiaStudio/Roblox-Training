local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)
local PlayerMovement = LifetimeObject.new()

local RunService = game:GetService("RunService")

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass("Humanoid")

local collisionBodyPartsNames = { "UpperTorso", "Head", "LeftHand", "RightHand" }

local speedBase = 10
local speedMax = 100
local acceleration = 12
local jumpAccelerationPercentage = 0.3

local collidedInThisFrame = false

local function OnCharacterCollided(part: BasePart)
	if collidedInThisFrame == true then
		return
	end

	collidedInThisFrame = true

	humanoid.WalkSpeed = speedBase
end

local function SubscribeToBodyPartsEvents()
	for i, v in pairs(collisionBodyPartsNames) do
		local collisionBodyPart: BasePart = character:FindFirstChild(v)

		collisionBodyPart.Touched:Connect(OnCharacterCollided)
	end
end

function PlayerMovement:OnAwake()
	SubscribeToBodyPartsEvents()
end

function PlayerMovement:OnStart() end

function PlayerMovement:OnDestroy() end

local function Update(time, deltaTime)
	collidedInThisFrame = false

	local isMoving = humanoid.MoveDirection.Magnitude > 0
	local isJumping = humanoid:GetState() == Enum.HumanoidStateType.Freefall
	local _acceleration

	if isMoving == true then
		_acceleration = acceleration
	else
		_acceleration = acceleration * -1
	end

	if isJumping == true then
		_acceleration *= jumpAccelerationPercentage
	end

	humanoid.WalkSpeed += _acceleration * deltaTime

	humanoid.WalkSpeed = math.clamp(humanoid.WalkSpeed, 0, speedMax)
end

RunService.Stepped:Connect(Update)

return PlayerMovement
