local PlayerCollisionHandler = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Net = require(ServerScriptService.Server.Net)

local Players = game:GetService("Players")

local function SubscribePlayer(player: Player, character: Model)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

	humanoidRootPart.Touched:Connect(function(hit)
		local otherCharacter = hit.Parent
		local otherPlayer = Players:GetPlayerFromCharacter(otherCharacter)

		if otherPlayer ~= nil then
			local otherHumanoid: Humanoid = otherCharacter:FindFirstChildOfClass("Humanoid")
			local otherHumanoidRootPart = character:FindFirstChild("HumanoidRootPart")

			local otherPlayerSpeed = otherHumanoid.WalkSpeed
			local knockBackDirection: Vector3 = humanoidRootPart.CFrame.Position - otherHumanoidRootPart.CFrame.Position

			print(character.Name .. " and " .. otherPlayer.Name .. " collided!")

			Net.CollidedWithPlayer.Fire(player, otherPlayerSpeed, knockBackDirection)
		end
	end)

	print(`Subscribed player {character.Name}`)
end

local function SubscribeExistingPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character or player.CharacterAdded:Wait()

		SubscribePlayer(player, character)
	end
end

local function Initialize()
	SubscribeExistingPlayers()

	game.Players.PlayerAdded:Connect(function(newPlayer: Player)
		newPlayer.CharacterAdded:Connect(function(newCharacter: Model)
			SubscribePlayer(newPlayer, newCharacter)
		end)
	end)
end

Initialize()

return PlayerCollisionHandler
