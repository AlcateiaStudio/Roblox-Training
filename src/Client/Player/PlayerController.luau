local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)
local PlayerController = {}

local RunService = game:GetService("RunService")

local Net = require(ReplicatedStorage.Client.Net)

local DashPanelComponent = require(ReplicatedStorage.Shared.Components.DashPanelComponent)
local ObjectThatCausesDamageComponent = require(ReplicatedStorage.Shared.Components.ObjectThatCausesDamageComponent)

local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass("Humanoid")

local playerModule = (require)(localPlayer.PlayerScripts.PlayerModule)
local controls = playerModule:GetControls()

local PlayerState = { Normal = 0, TakingKnockBack = 1, Static = 2 }
local collisionBodyPartsNames = { "UpperTorso", "Head", "LeftHand", "RightHand" }

local speedBase = 10
local speedMaxNormal = 60
local speedMaxDashing = 140
local accelerationNormal = 12
local accelerationDashing = 100
local jumpAccelerationPercentage = 0.3

local minimunSpeedToKnockBack = 40
local speedDifferenceToKnockPlayer = 40

local knockBackDirection: Vector3 = Vector3.zero
local knockBackTime = 0
local knockBackTimeMax = 0.4

local playerState = PlayerState.Normal
local collidedInThisFrame = false
local canPlayerMove = true
local isPlayerDashing = false

local timeToUpdateSpeedOnServerMax = 0.5
local timeToUpdateSpeedOnServer = 0

local function OnCollidedWithPlayer(_otherPlayerSpeed: number, _knockBackDirection: Vector3)
	if playerState == PlayerState.TakingKnockBack or playerState == PlayerState.Static then
		return
	end

	local currentSpeed = humanoid.WalkSpeed
	local speedDifference = math.abs(currentSpeed - _otherPlayerSpeed)

	print(`{localPlayer.Name} on collide with player, CS: {currentSpeed}, OPS {_otherPlayerSpeed}, SD {speedDifference}`)

	if currentSpeed < minimunSpeedToKnockBack and _otherPlayerSpeed < minimunSpeedToKnockBack then
		return
	end

	if currentSpeed > _otherPlayerSpeed then
		if speedDifference < speedDifferenceToKnockPlayer then
			PlayerController:TakeKnockBack(speedDifference, _knockBackDirection)
		end
	else
		if speedDifference < speedDifferenceToKnockPlayer then
			PlayerController:TakeKnockBack(speedDifference, _knockBackDirection)
		else
			PlayerController:TakeDamage(speedDifference, _knockBackDirection)
		end
	end
end

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
	PlayerController:TakeDamage(_knockBackSpeed, _knockBackDirection)
end

local function OnPlayerDashStateChanged(_isDashEnabled: boolean)
	isPlayerDashing = _isDashEnabled
end

local function CheckIfStateIsValid(_playerState: number)
	for _, playerStateValue in pairs(PlayerState) do
		if _playerState == playerStateValue then
			return true
		end
	end

	return false
end

local function OnUpdatePlayerStateFromServer(_playerState: number)
	if CheckIfStateIsValid(_playerState) == false then
		warn(`O estado \"{_playerState}\" nao e valido!`)

		return
	end

	PlayerController:SetPlayerState(_playerState)
end

function PlayerController:SubscribeToBodyPartsEvents()
	for _, v in pairs(collisionBodyPartsNames) do
		local collisionBodyPart = character:FindFirstChild(v)

		if collisionBodyPart:IsA("BasePart") then
			collisionBodyPart.Touched:Connect(OnCharacterCollided)
		else
			warn(`O objeto com nome \"{v}\" nao e uma BasePart!`)
		end
	end
end

function PlayerController:SetCanPlayerMove(_canPlayerMove)
	canPlayerMove = _canPlayerMove

	humanoid.AutoRotate = canPlayerMove

	if _canPlayerMove == false then
		humanoid.WalkSpeed = 0
	end
end

function PlayerController:SetPlayerState(_playerState: number)
	playerState = _playerState

	self:SetCanPlayerMove(playerState == PlayerState.Normal)

	if playerState == PlayerState.TakingKnockBack then
		controls:Disable()
	else
		controls:Enable()
	end
end

function PlayerController:_UpdateVelocity(deltaTime)
	local isMoving = humanoid.MoveDirection.Magnitude > 0
	local isJumping = humanoid:GetState() == Enum.HumanoidStateType.Freefall
	local _acceleration
	local _speedMax

	if isPlayerDashing == true then
		_speedMax = speedMaxDashing
	else
		_speedMax = speedMaxNormal
	end

	if isMoving == true then
		if isPlayerDashing == true then
			_acceleration = accelerationDashing
		else
			_acceleration = accelerationNormal
		end
	else
		_acceleration = 0
	end

	if isJumping == true then
		_acceleration *= jumpAccelerationPercentage
	end

	if isMoving == false and isJumping == false then
		humanoid.WalkSpeed = 0
	else
		humanoid.WalkSpeed += _acceleration * deltaTime
		humanoid.WalkSpeed = math.clamp(humanoid.WalkSpeed, speedBase, _speedMax)
	end
end

function PlayerController:_DoKnockBack(deltaTime)
	knockBackTime -= deltaTime

	if knockBackTime <= 0 then
		humanoid.WalkSpeed = 0
		self:SetPlayerState(PlayerState.Normal)
	end
end

function PlayerController:_UpdateSpeedOnServer(deltaTime: number)
	timeToUpdateSpeedOnServer -= deltaTime

	if timeToUpdateSpeedOnServer <= 0 then
		timeToUpdateSpeedOnServer = timeToUpdateSpeedOnServerMax

		Net.PlayerUpdatedSpeed.Fire(humanoid.WalkSpeed)
	end
end

function PlayerController:TakeDamage(_knockBackSpeed: number, _knockBackDirection: Vector3)
	if playerState == PlayerState.TakingKnockBack or playerState == PlayerState.Static then
		return
	end

	self:TakeKnockBack(_knockBackSpeed, _knockBackDirection)

	--TODO: perder moedas
end

function PlayerController:TakeKnockBack(_knockBackSpeed: number, _knockBackDirection: Vector3)
	if playerState == PlayerState.TakingKnockBack or playerState == PlayerState.Static then
		return
	end

	self:SetPlayerState(PlayerState.TakingKnockBack)

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

function PlayerController:OnAwake()
	self:SubscribeToBodyPartsEvents()
end

function PlayerController:OnStart() end

function PlayerController:OnDestroy() end

local function Update(time, deltaTime)
	collidedInThisFrame = false

	if playerState == PlayerState.Normal then
		PlayerController:_UpdateVelocity(deltaTime)
	elseif playerState == PlayerState.TakingKnockBack then
		PlayerController:_DoKnockBack(deltaTime)
	end

	PlayerController:_UpdateSpeedOnServer(deltaTime)
end

RunService.Stepped:Connect(Update)

Net.CollidedWithPlayer.On(OnCollidedWithPlayer)
Net.UpdatePlayerState.On(OnUpdatePlayerStateFromServer)

ObjectThatCausesDamageComponent:RegisterCauseDamageCallback(OnPlayerTakeDamage)
DashPanelComponent:RegisterDashStateChangedCallback(OnPlayerDashStateChanged)

return LifetimeObject.extend(PlayerController, "PlayerController")
