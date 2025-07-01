local PlayerCollisionHandler = {}

local Players = game:GetService("Players")

local function SubscribePlayer(character: Model)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	humanoidRootPart.Touched:Connect(function(hit)
		local otherPlayer = Players:GetPlayerFromCharacter(hit.Parent)

		if otherPlayer ~= nil then
			print(character.Name .. " and " .. otherPlayer.Name .. " collided!")
			--TODO: invoke event
		end
	end)

	print(`Subscribed player {character.Name}`)
end

local function SubscribeExistingPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character or player.CharacterAdded:Wait()
		SubscribePlayer(character)
	end
end

local function Initialize()
	SubscribeExistingPlayers()

	game.Players.PlayerAdded:Connect(function(newPlayer)
		newPlayer.CharacterAdded:Connect(SubscribePlayer)
	end)
end

Initialize()

return PlayerCollisionHandler
