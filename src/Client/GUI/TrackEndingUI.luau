--// Services //--
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Folders //--
local assets = ReplicatedStorage.Assets
local client = ReplicatedStorage.Client
local shared = ReplicatedStorage.Shared
local packages = ReplicatedStorage.Packages

--// Imports //--
local Component = require(packages.Component)
local EndingPlayerEntry = require(client.GUI.Components.EndingPlayerEntry)
local LifetimeObject = require(shared.System.LifetimeObject)
local Net = require(client.Net)

--// Prefabs //--
local endingPlayerEntryPrefab = assets.EndingPlayerEntry

--// Types //--
type TrackEnding = {
	ScreenGui: ScreenGui,
}

local trackEnding: TrackEnding
local localPlayer = Players.LocalPlayer

local TrackEndingUI = {}

local playerEntries = {} :: { EndingPlayerEntry.PlayerEntry }

--------------------------------------------------------------------------------
--// Track Ending Methods //--
--------------------------------------------------------------------------------
function TrackEndingUI:CreatePlayerEntry(player: Player, position: number)
	local playerEntryInstance: Instance = endingPlayerEntryPrefab:Clone()
	EndingPlayerEntry:WaitForInstance(playerEntryInstance)
		:andThen(function(component: EndingPlayerEntry.PlayerEntry)
			component:SetUpFor(player, position)
			table.insert(playerEntries, component)
		end)
		:catch(function(err)
			warn("Failed to create player entry:", err)
		end)
end
--------------------------------------------------------------------------------
--// UI Lifecycle Methods //--
--------------------------------------------------------------------------------
function TrackEndingUI:OnAwake()
	if not trackEnding then
		self:GetUI()
	end
end

function TrackEndingUI:OnStart()
	Net.RaceFinished.On(function(playersInRace)
		print("Race finished. Here are the players: ", playersInRace)
	end)
end

function TrackEndingUI:GetUI()
	trackEnding = {
		ScreenGui = nil,
	}

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	trackEnding.ScreenGui = playerGui:WaitForChild("TrackEnding")

	-- Validation
	assert(trackEnding.ScreenGui.ResetOnSpawn == false, "UI should not reset on spawn")
end

return LifetimeObject.extend(TrackEndingUI, "TrackEndingUI")
