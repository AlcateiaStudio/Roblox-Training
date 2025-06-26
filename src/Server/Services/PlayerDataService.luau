local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)
local ProfileStore = require(ServerScriptService.Server.ProfileStore)
local Replica = require(ServerScriptService.Server.ReplicaServer)

local SAVE_KEY = "PlayerData"
local REPLICA_TOKEN = Replica.Token(SAVE_KEY)

export type SaveKey = "DuoWins" | "EscapistWins" | "Captures" | "Rescues" | "CorrectAnswers" | "DoorsUnlocked"
export type SaveData = {
	NewPlayer: boolean?,
}

local PROFILE_TEMPLATE: SaveData = {
	NewPlayer = true,
}

local PlayerStore = ProfileStore.New(SAVE_KEY, PROFILE_TEMPLATE)
local Profiles: { [Player]: {
	Profile: ProfileStore.Profile<SaveData>,
	Replica: Replica.Replica,
} } = {}

-- Create PlayerDataService that inherits from LifetimeObject
local PlayerDataService = {}
PlayerDataService.Name = "PlayerDataService"

local function onPlayerReady(player: Player)
	-- Start a profile session for this player's data:
	local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	-- Handling new profile session or failure to start it:
	if profile ~= nil then
		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from PROFILE_TEMPLATE (optional)

		profile.OnSessionEnd:Connect(function()
			Profiles[player] = nil
			player:Kick(`Profile session end - Please rejoin`)
		end)

		if player.Parent == Players then
			local replica = Replica.New({
				Token = REPLICA_TOKEN,
				Data = profile.Data,
				Tags = { UserId = player.UserId },
			})

			Profiles[player] = {
				Profile = profile,
				Replica = replica,
			}

			replica:Subscribe(player)
			print(`Profile and Replica loaded for {player.DisplayName}!`, Profiles[player])
		else
			-- The player has left before the profile session started
			profile:EndSession()
		end
	else
		-- This condition should only happen when the Roblox server is shutting down
		player:Kick(`Profile load fail! Please rejoin`)
	end
end

function PlayerDataService:OnAwake()
	self.connections = {}
end

function PlayerDataService:OnStart()
	-- Handle players already in the game when the service starts
	for _, player in Players:GetPlayers() do
		if Replica.ReadyPlayers[player.UserId] then
			task.spawn(onPlayerReady, player)
		else
			warn(`{player.DisplayName} is not ready yet, can't Replicate`)
		end
	end

	-- Connect to new players joining
	self.connections.newReadyPlayer = Replica.NewReadyPlayer:Connect(onPlayerReady)

	-- Handle players leaving
	self.connections.playerRemoving = Players.PlayerRemoving:Connect(function(player)
		local profile = Profiles[player] and Profiles[player].Profile
		if profile ~= nil then
			print(`Profile saved for {player.DisplayName}!`, profile.Data)
			profile:EndSession()
		else
			warn(`Profile not found for {player.DisplayName}, data was probably manually wiped. If not, this is a bug!`)
		end
	end)
end

function PlayerDataService:OnDestroy()
	-- Clean up connections
	for _, connection in pairs(self.connections) do
		if connection then
			connection:Disconnect()
		end
	end
	self.connections = {}

	-- End all active profile sessions
	for player, data in pairs(Profiles) do
		if data.Profile then
			data.Profile:EndSession()
		end
	end
	Profiles = {}
end

local function WaitForProfile(player: Player, timeout: number?)
	local timeoutDuration = timeout or 10 -- Default 10 second timeout
	local startTime = tick()

	while tick() - startTime < timeoutDuration do
		if Profiles[player] and Profiles[player].Profile then
			return Profiles[player].Profile
		end
		task.wait(0.1) -- Check every 0.1 seconds
	end

	warn(`Timeout waiting for profile for {player.DisplayName}`)
	return nil
end

function PlayerDataService:AddToData(player: Player, key: SaveKey, value: number)
	local profile = Profiles[player].Profile
	local replica = Profiles[player].Replica
	if profile ~= nil and profile.Data[key] ~= nil then
		-- profile.Data[key] = profile.Data[key] + value
		replica:Set({ key }, profile.Data[key] + value)
		print(`Added {value} to {key} for {player.DisplayName}. New value: {profile.Data[key]}`)
	else
		warn(`Profile not found for {player.DisplayName} or key {key} not found`)
	end
end

function PlayerDataService:SetData(player: Player, key: SaveKey, value: number)
	local profile = Profiles[player].Profile
	local replica = Profiles[player].Replica
	if profile ~= nil and profile.Data[key] ~= nil then
		replica:Set({ key }, value)
		print(`Set {key} to {value} for {player.DisplayName}. New value: {profile.Data[key]}`)
	else
		warn(`Profile not found for {player.DisplayName} or key {key} not found`)
	end
end

function PlayerDataService:GetPlayerData(player: Player): SaveData?
	local profile = WaitForProfile(player)
	if profile ~= nil then
		return profile.Data
	else
		warn(`Profile not found for {player.DisplayName}`)
		return nil
	end
end

function PlayerDataService:WipePlayerData(player: Player)
	local profile = Profiles[player].Profile
	if not profile then
		return
	end

	if profile:IsActive() then
		profile:EndSession()
		PlayerStore:RemoveAsync(`{player.UserId}`)
		player:Kick("Data Wiped")
	end
end

return LifetimeObject.extend(PlayerDataService, "PlayerDataService")
