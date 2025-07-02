local PlayerCollisionHandler = {}

local RunService = game:GetService("RunService")

local ServerScriptService = game:GetService("ServerScriptService")
local Net = require(ServerScriptService.Server.Net)

local Players = game:GetService("Players")

local playersToTestCollision = {}
local playerCollisionOverlapParams: OverlapParams
local playerSizeMultiplier = 1.5

local timeToTestCollisionMax = 0.1
local timeToTestCollision = 0

local function CreateOverlapParams()
	playerCollisionOverlapParams = OverlapParams.new()

	playerCollisionOverlapParams.FilterType = Enum.RaycastFilterType.Include
	playerCollisionOverlapParams.FilterDescendantsInstances = {}
end

local function GetPlayersCollisions()
	local playersCollisions = {}

	for _, playerToTestCollision in pairs(playersToTestCollision) do
		local humanoidRootPart = playerToTestCollision.humanoidRootPart

		table.insert(playersCollisions, humanoidRootPart)
	end

	return playersCollisions
end

local function GetPlayerSpeed(player: Player)
	for _, playerToTestCollision in pairs(playersToTestCollision) do
		if playerToTestCollision.player == player then
			return playerToTestCollision.speed
		end
	end

	warn(`Nao foi encontrada nenhuma velocidade para o player \"{player}\"!`)

	return 0
end

local function CheckCollisionBetweenPlayers()
	for _, playerToTestCollision in pairs(playersToTestCollision) do
		local player = playerToTestCollision.player
		local humanoidRootPart = playerToTestCollision.humanoidRootPart

		local partsThatCollideWithPlayer =
			workspace:GetPartBoundsInBox(humanoidRootPart:GetPivot(), humanoidRootPart.Size * playerSizeMultiplier, playerCollisionOverlapParams)

		for _, partThatCollidesWithPlayer in pairs(partsThatCollideWithPlayer) do
			local otherCharacter = partThatCollidesWithPlayer.Parent
			local otherPlayer = Players:GetPlayerFromCharacter(otherCharacter)

			if otherPlayer ~= nil and otherPlayer ~= player then
				local otherHumanoidRootPart = otherCharacter:FindFirstChild("HumanoidRootPart") :: BasePart

				local otherPlayerSpeed = GetPlayerSpeed(otherPlayer)
				local knockBackDirection: Vector3 = humanoidRootPart.CFrame.Position - otherHumanoidRootPart.CFrame.Position

				Net.CollidedWithPlayer.Fire(player, otherPlayerSpeed, knockBackDirection)
			end
		end
	end
end

local function SubscribePlayer(_player: Player, _character: Model)
	local _humanoidRootPart: BasePart = _character:FindFirstChild("HumanoidRootPart") :: BasePart

	local playerToTestCollision = { player = _player, character = _character, humanoidRootPart = _humanoidRootPart, speed = 0 }

	table.insert(playersToTestCollision, playerToTestCollision)

	playerCollisionOverlapParams.FilterDescendantsInstances = GetPlayersCollisions()
end

local function SubscribeExistingPlayers()
	for _, player in pairs(Players:GetPlayers()) do
		local character = player.Character or player.CharacterAdded:Wait()

		SubscribePlayer(player, character)
	end
end

local function UpdatePlayerSpeed(player: Player, speed: number)
	for _, playerToTestCollision in pairs(playersToTestCollision) do
		if playerToTestCollision.player == player then
			playerToTestCollision.speed = speed

			break
		end
	end
end

local function Update(deltaTime: number)
	timeToTestCollision -= deltaTime

	if timeToTestCollision <= 0 then
		timeToTestCollision = timeToTestCollisionMax

		CheckCollisionBetweenPlayers()
	end
end

local function Initialize()
	CreateOverlapParams()

	SubscribeExistingPlayers()

	game.Players.PlayerAdded:Connect(function(newPlayer: Player)
		newPlayer.CharacterAdded:Connect(function(newCharacter: Model)
			SubscribePlayer(newPlayer, newCharacter)
		end)
	end)

	RunService.Heartbeat:Connect(Update)

	Net.PlayerUpdatedSpeed.On(UpdatePlayerSpeed)
end

Initialize()

return PlayerCollisionHandler
