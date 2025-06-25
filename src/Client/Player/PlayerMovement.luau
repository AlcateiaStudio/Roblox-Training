local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)
local PlayerMovement = LifetimeObject.new()

local RunService = game:GetService("RunService")

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass("Humanoid")

local collisionBodyPartsNames = { "UpperTorso", "Head", "LeftHand", "RightHand" }

local collidedInThisFrame = false

local function OnCharacterCollided(part: BasePart)
	if collidedInThisFrame == true then
		return
	end

	collidedInThisFrame = true

	print(`Colidiu com {part}`)
end

local function SubscribeToBodyPartsEvents()
	for i, v in pairs(collisionBodyPartsNames) do
		local collisionBodyPart: BasePart = character:FindFirstChild(v)

		collisionBodyPart.Touched:Connect(OnCharacterCollided)
	end
end

function PlayerMovement:OnAwake()
	SubscribeToBodyPartsEvents()

	humanoid.WalkSpeed = 120
end

function PlayerMovement:OnStart() end

function PlayerMovement:OnDestroy() end

local function Update()
	collidedInThisFrame = false

	--print(humanoid.MoveDirection)
end

RunService.Stepped:Connect(Update)

return PlayerMovement
