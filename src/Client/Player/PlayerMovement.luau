local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)
local PlayerMovement = {}

local RunService = game:GetService("RunService")

local Net = require(ReplicatedStorage.Client.Net)

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass("Humanoid")

local playerModule = require(localPlayer.PlayerScripts.PlayerModule)
local controls = playerModule:GetControls()

local PlayerState = { Normal = 0, TakingDamage = 1, Static = 3 }
local collisionBodyPartsNames = { "UpperTorso", "Head", "LeftHand", "RightHand" }

local speedBase = 10
local speedMax = 100
local acceleration = 12
local jumpAccelerationPercentage = 0.3

local knockBackDirection: Vector3 = Vector3.zero
local knockBackTime = 0
local knockBackTimeMax = 0.4

local playerState = PlayerState.Normal
local collidedInThisFrame = false
local canPlayerMove = true

local function OnCharacterCollided(part: BasePart)
	if collidedInThisFrame == true then
		return
	end

	if part:HasTag("Environment") == false then
		return
	end

	collidedInThisFrame = true

	humanoid.WalkSpeed = speedBase
end

local function OnPlayerTakeDamage(_knockBackSpeed: number, _knockBackDirection: Vector3)
	PlayerMovement:TakeDamage(_knockBackSpeed, _knockBackDirection)
end

function PlayerMovement:SubscribeToBodyPartsEvents()
	for i, v in pairs(collisionBodyPartsNames) do
		local collisionBodyPart = character:FindFirstChild(v)

		if collisionBodyPart:IsA("BasePart") then
			collisionBodyPart.Touched:Connect(OnCharacterCollided)
		else
			warn(`O objeto com nome \"{v}\" nao e uma BasePart!`)
		end
	end
end

function PlayerMovement:SetCanPlayerMove(_canPlayerMove)
	canPlayerMove = _canPlayerMove

	humanoid.AutoRotate = canPlayerMove

	if _canPlayerMove == false then
		humanoid.WalkSpeed = 0
	end
end

function PlayerMovement:SetPlayerState(_playerState: number)
	playerState = _playerState

	self:SetCanPlayerMove(playerState == PlayerState.Normal)

	if playerState == PlayerState.TakingDamage then
		controls:Disable()
	else
		controls:Enable()
	end
end

function PlayerMovement:UpdateVelocity(deltaTime)
	local isMoving = humanoid.MoveDirection.Magnitude > 0
	local isJumping = humanoid:GetState() == Enum.HumanoidStateType.Freefall
	local _acceleration

	if isMoving == true then
		_acceleration = acceleration
	else
		_acceleration = 0
	end

	if isJumping == true then
		_acceleration *= jumpAccelerationPercentage
	end

	if isMoving == false and isJumping == false then
		humanoid.WalkSpeed = speedBase
	end

	humanoid.WalkSpeed += _acceleration * deltaTime

	humanoid.WalkSpeed = math.clamp(humanoid.WalkSpeed, speedBase, speedMax)
end

function PlayerMovement:DoKnockBack(deltaTime)
	knockBackTime -= deltaTime

	if knockBackTime <= 0 then
		self:SetPlayerState(PlayerState.Normal)
	end
end

function PlayerMovement:TakeDamage(_knockBackSpeed: number, _knockBackDirection: Vector3)
	if playerState == PlayerState.Static then
		return
	end

	self:SetPlayerState(PlayerState.TakingDamage)

	knockBackDirection = _knockBackDirection
	knockBackTime = knockBackTimeMax

	humanoid.WalkSpeed = _knockBackSpeed
	humanoid:Move(knockBackDirection, false)

	humanoid.Jump = true

	character.PrimaryPart.CFrame = CFrame.new(
		character.PrimaryPart.Position,
		character.PrimaryPart.Position + (Vector3.new(_knockBackDirection.X, 0, _knockBackDirection.Z) * -1)
	)
end

function PlayerMovement:OnAwake()
	self:SubscribeToBodyPartsEvents()
end

function PlayerMovement:OnStart() end

function PlayerMovement:OnDestroy() end

local function Update(time, deltaTime)
	collidedInThisFrame = false

	if playerState == PlayerState.Normal then
		PlayerMovement:UpdateVelocity(deltaTime)
	elseif playerState == PlayerState.TakingDamage then
		PlayerMovement:DoKnockBack(deltaTime)
	end
end

RunService.Stepped:Connect(Update)

Net.PlayerTakeDamage.On(OnPlayerTakeDamage)

return LifetimeObject.extend(PlayerMovement, "PlayerMovement")
