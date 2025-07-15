local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LifetimeObject = require(ReplicatedStorage.Shared.System.LifetimeObject)
local Net = require(ReplicatedStorage.Client.Net)

--// Type Definitions //--
export type Hud = {
	ScreenGui: ScreenGui,
	Coins: TextLabel,
	Placement: PlacementTexts,
	Speed: TextLabel,
	Timer: TimerTexts,
	TrackImage: ImageLabel,
	Laps: LapsTexts,
}

export type TimerTexts = {
	Minutes: TextLabel,
	Seconds: TextLabel,
	Milliseconds: TextLabel,
}

export type PlacementTexts = {
	Placement: TextLabel,
	Ending: TextLabel,
}

export type LapsTexts = {
	CurrentLap: TextLabel,
	TotalLaps: TextLabel,
}

--// Static Vars //--
local hud: Hud = nil
local localPlayer = Players.LocalPlayer

--------------------------------------------------------------------------------
--// Private Functions //--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--// Module Functions //--
--------------------------------------------------------------------------------
local TrackHUD = {}

function TrackHUD:OnAwake()
	if not hud then
		TrackHUD:GetUI()
	end
end

function TrackHUD:OnStart()
	Net.RaceStarted.On(function(...)
		self:Show(...)
	end)

	Net.RaceFinished.On(function(...)
		self:Hide(...)
	end)

	self:Hide()
end

function TrackHUD:GetUI()
	hud = {
		ScreenGui = nil,
		Coins = nil,
		Placement = nil,
		Speed = nil,
		Timer = nil,
		TrackImage = nil,
		Laps = nil,
	}

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	hud.ScreenGui = playerGui:WaitForChild("TrackHUD")
	local configuration = hud.ScreenGui:WaitForChild("Configuration") :: Configuration
	local minutes = configuration:WaitForChild("MinutesText") :: ObjectValue
	local seconds = configuration:WaitForChild("SecondsText") :: ObjectValue
	local milliseconds = configuration:WaitForChild("MiliSecondsText") :: ObjectValue
	hud.Timer = {
		Minutes = minutes.Value :: TextLabel,
		Seconds = seconds.Value :: TextLabel,
		Milliseconds = milliseconds.Value :: TextLabel,
	}

	local trackImage = configuration:WaitForChild("TrackImage") :: ObjectValue
	hud.TrackImage = trackImage.Value :: ImageLabel

	local placementText = configuration:WaitForChild("PlacementNumberText") :: ObjectValue
	local placementEndingText = configuration:WaitForChild("PlacementEndingSymbolText") :: ObjectValue
	hud.Placement = {
		Placement = placementText.Value :: TextLabel,
		Ending = placementEndingText.Value :: TextLabel,
	}

	local currentLapText = configuration:WaitForChild("CurrentLapText") :: ObjectValue
	local totalLapsText = configuration:WaitForChild("TotalLapsText") :: ObjectValue

	hud.Laps = {
		CurrentLap = currentLapText.Value :: TextLabel,
		TotalLaps = totalLapsText.Value :: TextLabel,
	}

	-- Validation
	assert(hud.ScreenGui.ResetOnSpawn == false, "UI should not reset on spawn")
end

function TrackHUD:GetTimeTexts(): TimerTexts
	if not hud then
		self:GetUI()
	end

	return hud.Timer
end

function TrackHUD:GetTrackImage(): ImageLabel
	if not hud then
		self:GetUI()
	end

	return hud.TrackImage
end

function TrackHUD:GetPlacementTexts(): PlacementTexts
	if not hud then
		self:GetUI()
	end

	return hud.Placement
end

function TrackHUD:GetLapsTexts(): LapsTexts
	if not hud then
		self:GetUI()
	end

	return hud.Laps
end

function TrackHUD:Show()
	hud.ScreenGui.Enabled = true
end

function TrackHUD:Hide()
	hud.ScreenGui.Enabled = false
end

return LifetimeObject.extend(TrackHUD, "TrackHUD")
