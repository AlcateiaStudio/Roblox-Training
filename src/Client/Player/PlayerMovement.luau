local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)
local PlayerMovement = LifetimeObject.new()

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass("Humanoid")

local RunService = game:GetService("RunService")
-- Criar Update

function PlayerMovement:OnAwake()
	print("Awakei")
	humanoid.WalkSpeed = 120
end

function PlayerMovement:OnStart() end

function PlayerMovement:OnDestroy() end

local function Update()
	print("Update")
end

RunService.Stepped:Connect(Update)

return PlayerMovement
